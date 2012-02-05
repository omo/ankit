
require 'ankit/command'
require 'ankit/coming_command'
require 'ankit/fail_command'
require 'ankit/pass_command'
require 'ankit/round_command'
require 'highline'

module Ankit
  
  module Challenge
    class Slot < Struct.new(:name, :card, :event); end
    
    class Progress
      def initialize(slots)
        @slots = slots
      end
    end

    class State
      def initialize(line)
        @line = line
      end
    end

    class QuestionState < State
    end

    class FailedState < State
    end

    class PassedState < State
    end

    class BreakingState < State
    end
  end

  class ChallengeCommand < Command
    include RoundCounting
    available

    DEFAULT_COUNT = -1

    def execute()
      sorted_names = each_sorted_events.map(&:name)
      toprint = options[:name] ? sorted_names : FindCommand.new(runtime, sorted_names).to_enum(:each_card_path)
      toprint.take(0 <= count ? count : sorted_names.size).each { |i| runtime.stdout.print("#{i}\n") }
    end
end
