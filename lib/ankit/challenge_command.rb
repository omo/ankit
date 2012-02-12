# -*- coding: utf-8 -*-

require 'ankit/command'
require 'ankit/coming_command'
require 'ankit/fail_command'
require 'ankit/find_command'
require 'ankit/pass_command'
require 'ankit/round_command'
require 'highline'
require 'diff/lcs'

module Ankit

  class StylableText
    def self.styled_text(text, type)
      case type
      when :hidden
        text.gsub(/\w/, "*")
      when :failed
        HighLine.color(text, HighLine::RED_STYLE)
      when :passed
        HighLine.color(text, HighLine::GREEN_STYLE)
      when :plus
        HighLine.color(text, HighLine::RED_STYLE)
      when :minus
        HighLine.color(text, HighLine::REVERSE_STYLE)
      else
        raise
      end
    end

    def initialize(text); @text = text; end

    def decorated(type)
      decorated = @text.gsub(/\[(.*?)\]/) { |t| self.class.styled_text($1, type) }
      decorated != @text ? decorated : self.class.styled_text(@text, type)
    end

    def diff(orig)
      return @text if @text.empty?

      changes = Diff::LCS.sdiff(orig, @text)
      changes.map do |ch|
        case ch.action
        when "="
          ch.new_element
        when "!"
          self.class.styled_text(ch.new_element, :plus)
        when "-"
          self.class.styled_text(ch.old_element, :minus)
        when "+"
          self.class.styled_text(ch.new_element, :plus)
        else
          raise
        end
      end.join("")
    end
  end

  class Card
    def hidden_original; StylableText.new(self.original).decorated(:hidden); end
    def diff_from_original(text) StylableText.new(self.plain_original).diff(text); end
  end

  module Challenge
    class Slot < Struct.new(:path, :rating, :event); end

    class Progress
      include CardHappening, CardNaming

      attr_reader :runtime, :slots, :index, :npassed, :nfailed

      def initialize(runtime, slots)
        @runtime, @slots, @index = runtime, slots, 0
        @npassed = @nfailed = 0
      end

      def current_card
        # XXX: might be better to cache
        Card.parse(open(current_path, "r") { |f| f.read })
      end

      def last_slot; @slots[@index-1]; end
      def current_slot; @slots[@index]; end
      def current_path; current_slot.path; end
      def size; @slots.size; end
      def over?; @slots.size <= @index; end

      def fail
        unless current_slot.rating
          last_slot = current_slot
          last_slot.rating = :failed
          last_slot.event = make_happen(FailCommand::EVENT_HAPPENING, to_card_name(current_path))
        end
        
        @nfailed += 1
      end

      def pass
        unless current_slot.rating
          last_slot = current_slot
          last_slot.rating = :passed
          last_slot.event = make_happen(PassCommand::EVENT_HAPPENING, to_card_name(current_path))
        end

        @npassed += 1
        @index += 1
      end
    end

    class State
      attr_reader :progress, :last_answer

      def initialize(progress, last_answer=nil)
        @progress, @last_answer = progress, last_answer
      end

      def keep_pumping_until(&block)
        state = self
        until block.call(state)
          state = state.pump
        end
      end

      def clear_screen
        runtime.stdout.print("\033[2J")
        h = HighLine::SystemExtensions.terminal_size[0]
        runtime.stdout.print("\033[#{h}0A")
      end

      def say(msg, type=:progress)
        line.say(message_for(msg, type))
      end

      def show_and_ask_enter(msg, type)
        line.ask(message_for(msg, type) + " ") { |q| q.readline = true }
      end

      def ask(msg="", type=:ask)
        line.ask(message_for(msg, type)) { |q| q.readline = true }
      end

      def over?; false; end
      def runtime; progress.runtime; end
      def line; progress.runtime.line; end

      private
      
      def message_for(body, type)
        case type
        when :progress
          " #{progress.index}/#{progress.size}: "
        when :fail
          StylableText.new("FAIL: ").decorated(:failed)
        when :pass
          StylableText.new("PASS: ").decorated(:passed)
        when :ask
          "    > "
        when :hit_return
          "    < "
        when :cont
          "      "
        else
          raise "Unknown header type:#{type}"
        end + body
      end

      def ask_header; "    > "; end
    end

    # XXX: test
    class EditState < State
      def pump
        # XXX: makes configurable
        system("vi " + progress.current_path)
        QuestionState.new(progress)
      end
    end

    class QuestionState < State
      def pump
        clear_screen
        card = progress.current_card
        say("#{card.translation}")
        say("#{card.hidden_original}", :cont)
        answered = ask().strip
        m = /^\/(\w+)/.match(answered) 
        if m
          pump_command($1)
        else
          (card.match?(answered.strip) ? PassedState : FailedState).new(progress, answered)
        end
      end

      def pump_command(command)
        case command
        when "edit"
          EditState.new(progress)
        else
          raise
        end
      end
    end

    class FailedState < State
      def pump
        progress.fail
        diff_from_original = progress.current_card.diff_from_original(last_answer)
        say("#{diff_from_original}", :fail)
        ask("", :hit_return)
        QuestionState.new(progress)
      end
    end

    class PassedState < State
      def pump
        card = progress.current_card
        progress.pass
        last_maturity = progress.last_slot.event.maturity
        say("Maturity: #{last_maturity}", :pass)
        ask("", :hit_return)
        progress.over? ? BreakingState.new(progress) : QuestionState.new(progress)
      end
    end

    class BreakingState < State
      def pump
        case ask_more
        when :yes
          initial_state
        when :no
          OverState.new(progress)
        else
          # TODO: handle help
          self
        end
      end

      def ask_more
        case line.ask("More(y/n/?) ").strip
        when /^y/, ""
          :yes
        when /^n/
          :no
        else
          :help
        end  
      end

      def coming_limit
        progress.size
      end
    end

    class OverState < State
      def over?; true; end
    end

    module Approaching
      def initial_state
        slots = Coming.coming_paths(self.runtime).take(self.coming_limit).map { |path| Slot.new(path, nil) }
        QuestionState.new(Progress.new(self.runtime, slots))
      end
    end

    class BreakingState; include Approaching; end
  end

  class ChallengeCommand < Command
    include Challenge, RoundCounting, Coming, Finding
    include Challenge::Approaching
    available

    define_options do |spec, options| 
      spec.on("-l", "--limit N") { |n| options[:limit] = n.to_i }
    end

    DEFAULT_COUNT = 5

    def execute()
      Signal.trap("INT") do
        STDERR.print("Quit.\n")
        exit(0)
      end

      initial_state.keep_pumping_until { |state| state.over? }
      Signal.trap("INT", "DEFAULT")
    end

    def coming_limit
      options[:limit] or DEFAULT_COUNT
    end
  end
end
