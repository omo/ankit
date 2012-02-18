
require 'ankit/card'
#require 'ankit/event_traversing_command'
require 'ankit/coming_command'

module Ankit
  class RoundCommand < Command
    available

    def execute()
      runtime.stdout.print("#{last_round} #{next_round}\n")
    end

    def next_round
      found = Coming.existing_events(runtime).first
      found ? found.next_round : 0
    end

    def last_round
      found = Coming.existing_events(runtime).max_by(&:round)
      found ? found.round : 0
    end
  end

  module RoundCounting
    def last_round; @last_round ||= RoundCommand.new(self.runtime).last_round; end
    def next_round; @next_round ||= RoundCommand.new(self.runtime).next_round; end
    def latest_round; last_round + 1; end
    def round_proceeded; @last_round = @next_round = nil; end
  end
end
