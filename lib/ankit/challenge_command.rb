
require 'ankit/command'
require 'ankit/coming_command'
require 'ankit/fail_command'
require 'ankit/find_command'
require 'ankit/pass_command'
require 'ankit/round_command'
require 'highline'

module Ankit
  
  module Challenge
    class Slot < Struct.new(:path, :rating); end

    class Progress
      attr_reader :runtime, :slots, :index, :npassed, :nfailed

      def initialize(runtime, slots)
        @runtime, @slots, @index = runtime, slots, 0
        @npassed = @nfailed = 0
      end

      def current_card
        # XXX: might be better to cache
        Card.parse(open(current_path, "r") { |f| f.read })
      end

      def current_slot; @slots[@index]; end
      def current_path; current_slot.path; end
      def size; @slots.size; end
      def over?; @slots.size <= @index; end

      def fail
        unless current_slot.rating
          current_slot.rating = :failed
          runtime.with_supressing_io { runtime.dispatch(["fail", current_path]) }
        end
        
        @nfailed += 1
      end

      def pass
        unless current_slot.rating
          current_slot.rating = :passed
          runtime.with_supressing_io { runtime.dispatch(["pass", current_path]) }
        end

        @npassed += 1
        @index += 1
      end
    end

    class State
      attr_reader :progress

      def initialize(progress)
        @progress = progress
      end

      def keep_pumping_until(&block)
        state = self
        until block.call(state)
          state = state.pump
        end
      end

      def say(msg, type=:progress)
        line.say(message_for(msg, type))
      end

      def show_and_ask_enter(msg, type)
        line.ask(message_for(msg, type) + " ") { |q| q.readline = true }
      end

      def ask(msg="")
        line.ask(ask_header + msg) { |q| q.readline = true }
      end

      def over?; false; end
      def runtime; progress.runtime; end
      def line; progress.runtime.line; end

      private
      
      def message_for(body, type)
        case type
        when :progress
          " #{progress.index}/#{progress.size}:"
        when :fail
          "FAIL:"
        when :pass
          "PASS:"
        else
          raise "Unknown header type:#{type}"
        end + body
      end

      def ask_header; "    > "; end
    end

    class QuestionState < State
      def pump
        # XXX: clear terminal
        card = progress.current_card
        say("#{card.translation}")
        # XXX: show hidden text.
        answered = ask()
        (card.match?(answered.strip) ? PassedState : FailedState).new(progress)
      end
    end

    class FailedState < State
      def pump
        progress.fail
        show_and_ask_enter("#{progress.current_card.original}", :fail)
        QuestionState.new(progress)
      end
    end

    class PassedState < State
      def pump
        card = progress.current_card
        progress.pass
        progress.over? ? BreakingState.new(progress) : QuestionState.new(progress)
      end
    end

    class BreakingState < State
      def pump
        return OverState.new(progress) unless ask_more
        initial_state
      end

      def ask_more
        line.agree("More(y/n)? ")
      end
    end

    class OverState < State
      def over?; true; end
    end

    module Approaching
      def initial_state
        slots = Coming.coming_paths(self.runtime).map { |path| Slot.new(path, nil) }
        QuestionState.new(Progress.new(self.runtime, slots))
      end
    end

    class BreakingState; include Approaching; end
  end

  class ChallengeCommand < Command
    include Challenge, RoundCounting, Coming, Finding
    include Challenge::Approaching
    available

    DEFAULT_COUNT = -1

    def execute()
      initial_state.keep_pumping_until { |state| state.over? }
    end
  end
end
