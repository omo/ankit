
require 'ankit/card'
#require 'ankit/event_traversing_command'
require 'ankit/coming_command'

module Ankit
  class RoundCommand < Command
    available

    def execute()
      runtime.stdout.print("#{value}\n")
    end

    def value; find + 1; end

    def find
      found = Coming.existing_events(runtime).min_by(&:round)
      found ? found.round : -1
    end
  end

  module RoundCounting
    def round; @round ||= RoundCommand.new(self.runtime).value; end
  end
end
