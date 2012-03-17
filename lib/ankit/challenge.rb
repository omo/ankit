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
      when :warn
        HighLine.color(text, HighLine::YELLOW_STYLE)
      when :passed
        HighLine.color(text, HighLine::GREEN_STYLE)
      when :pending
        HighLine.color(text, HighLine::DARK)
      when :correct
        HighLine.color(text, HighLine::GREEN_STYLE)
      when :wrong
        HighLine.color(text, HighLine::RED_STYLE)
      when :wrong
        HighLine.color(text, HighLine::RED_STYLE)
      when :fyi
        HighLine.color(text, HighLine::DARK)
      else
        raise
      end
    end

    def initialize(text); @text = text; end

    def decorated(type)
      raise
      decorated = @text.gsub(/\[(.*?)\]/) { |t|
        p Regexp::last_match.offset(0)
        self.class.styled_text($1, type)
      }
      decorated != @text ? decorated : self.class.styled_text(@text, type)
    end

  end

  class Card
    def hidden_original; decorated_original{ |m| StylableText.styled_text(m[1], :hidden) }; end
    def corrected_original_over(wrong)
      diff_from_original(wrong) do |ch|
        case ch.action
        when "="
          ch.new_element
        when "!", "+"
          StylableText.styled_text(ch.new_element, :correct)
        when "-"
          ""
        else
          raise
        end
      end
    end

    def hilight_against_original(wrong)
      diff_from_original(wrong) do |ch|
        case ch.action
        when "="
          ch.old_element
        when "!", "-"
          StylableText.styled_text(ch.old_element, :wrong)
        when "+"
          ""
        else
          raise
        end
      end
    end
  end

  module Challenge
    class Slot < Struct.new(:path, :rating, :event)
      def maturity; self.event ? self.event.maturity : 0; end
    end

    class Session < Struct.new(:runtime, :npassed, :nfailed, :mature_names)
      def self.make(runtime)
        self.new(runtime, 0, 0, [])
      end

      def summary_text
        total = self.npassed + self.nfailed
        return "" if 0 == total
        "#{self.npassed}/#{total} = #{self.npassed.to_f/total.to_f}, #mature: #{mature_names.size}"
      end
    end

    class Progress
      include CardHappening, CardNaming, RoundCounting

      attr_reader :session, :slots, :index, :this_round

      def initialize(session, slots)
        @session, @slots, @index = session, slots, 0
        @this_round = latest_round
      end

      def current_card
        # XXX: might be better to cache
        Card.parse(open(current_path, "r") { |f| f.read })
      end

      def round_delta
        latest_round - this_round
      end

      def runtime; @session.runtime; end
      def last_slot; @slots[@index-1]; end
      def current_slot; @slots[@index]; end
      def current_path; current_slot.path; end
      def size; @slots.size; end
      def over?; @slots.size <= @index; end
      def npassed; @slots.count { |c| c.rating == :passed }; end
      def nfailed; @slots.count { |c| c.rating == :failed }; end

      def already_failed?; current_slot.rating == :failed; end

      def attack
        current_slot.rating = :attacking unless current_slot.rating
        self
      end
        
      def fail
        unless already_failed?
          last_slot = current_slot
          last_slot.rating = :failed
          last_slot.event = make_happen(FailCommand::EVENT_HAPPENING, to_card_name(current_path), this_round)
        end
        
        self
      end

      def pass
        unless already_failed?
          last_slot = current_slot
          last_slot.rating = :passed
          last_slot.event = make_happen(PassCommand::EVENT_HAPPENING, to_card_name(current_path), this_round)
        end

        @index += 1
        self
      end

      def indicator
        @slots.inject("") do |a, i|
          a += case i.rating
               when :failed; "x"
               when :passed; "o"
               when :attacking; "*"
               else;         "-"
               end
        end
      end

      def styled_indicator
        indicator.to_enum(:each_char).map do |i|
          case i
          when "x"; StylableText.styled_text(i, :failed)
          when "o"; StylableText.styled_text(i, :passed)
          when "-"; StylableText.styled_text(i, :pending)
          else; i
          end
        end.join
      end

      def update_session
        session.npassed += npassed
        session.nfailed += nfailed
        session.mature_names = (session.mature_names + slots.select{ |s| 1 < s.maturity }.map(&:path)).uniq
      end

      def maturities; slots.map(&:maturity);  end
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

      # http://7ujm.net/etc/esc.html
      def erase_last
        runtime.stdout.print("\033[1A")
      end

      def clear_screen
        runtime.stdout.print("\033[2J")
        h = HighLine::SystemExtensions.terminal_size[0]
        runtime.stdout.print("\033[#{h}A")
      end

      def say(msg, type=:progress)
        line.say(message_for(msg, type))
      end

      def show_summary_status
        line.say("Round #{progress.this_round}: #{progress.styled_indicator}")

        if last_answer
          line.say(StylableText.styled_text("last: #{last_answer}", :fyi))
        else
          line.say("\n")
        end

      end

      def show_breaking_status
        show_summary_status
        line.say("Maturity: #{progress.maturities.map(&:to_s).join(',')}")
        line.say("Session: #{progress.session.summary_text}")
        line.say("next round will be +#{progress.round_delta}")
      end

      def show_header
        show_summary_status
        w = HighLine::SystemExtensions.terminal_size[1]
        line.say("\n")
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
      def session; progress.session; end

      private
      
      def message_for(body, type)
        case type
        when :progress
          "      "
        when :fail
          StylableText.styled_text("FAIL: ", :failed)
        when :typo
          StylableText.styled_text("TYPO: ", :warn)
        when :pass
          StylableText.styled_text("PASS: ", :passed)
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

    module SlashRecognizing
      def pump_slash_or(answered, &block)
        if /^\/(\w+)/.match(answered)
          pump_slash($1) 
        else
          block.call()
        end
      end

      def pump_slash(command)
        case command
        when "e", "edit"
          EditState.new(progress)
        when "z", "zero"
          QuestionState.new(progress)
        else
          MessageState.new(progress, "Unknown command: #{command} (Available: /edit, /zero)")
        end
      end
    end

    class MessageState < State
      include SlashRecognizing
      
      def initialize(progress, message)
        super(progress)
        @message = message
      end

      def pump
        say(@message, :fail) # XXX: should :error
        answered = ask().strip
        pump_slash_or(answered) do
          pump_slash(answered)
        end
      end
    end

    class QuestionState < State
      include SlashRecognizing

      def pump
        progress.attack
        clear_screen
        show_header
        card = progress.current_card
        say("#{card.translation}")
        say("#{card.hidden_original}", :cont)
        answered = ask().strip
        pump_slash_or(answered) do 
          case card.match?(answered.strip)
          when :match
            PassedState.new(progress, answered)
          when :wrong
            FailedState.new(progress, answered)
          when :typo
            TypoState.new(progress, answered)
          else
            raise
          end
        end
      end
    end

    class FailedStateBase < State
      include SlashRecognizing

      def pump
        original = progress.current_card.corrected_original_over(last_answer)
        typed = progress.current_card.hilight_against_original(last_answer)
        erase_last
        say("#{typed}", :ask)
        say("#{original}", decoration_type)
        answered = ask("", :hit_return)
        pump_slash_or(answered) do
          mark_progress
          QuestionState.new(progress)
        end
      end

    end

    class FailedState < FailedStateBase
      def mark_progress
        progress.fail
      end

      def decoration_type
        :fail
      end
    end

    class TypoState < FailedStateBase
      def mark_progress
        
      end

      def decoration_type
        :typo
      end
    end

    class PassedState < State
      include SlashRecognizing

      def pump
        progress.pass
        last_maturity = progress.last_slot.event.maturity
        progress.over? ? BreakingState.new(progress) : QuestionState.new(progress, last_answer)
      end
    end

    class BreakingState < State
      def pump
        progress.update_session
        clear_screen
        show_breaking_status

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
        QuestionState.new(Progress.new(self.session, slots))
      end
    end

    class BreakingState; include Approaching; end
  end
end
