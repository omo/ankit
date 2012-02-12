
require 'ankit/card'
#require 'ankit/event_traversing_command'
require 'ankit/coming_command'

module Ankit
  class RoundCommand < Command
    available

    def execute()
      runtime.stdout.print("#{find}\n")
    end

    def find
      found = Coming.existing_events(runtime).min_by(&:round)
      found ? found.round : 0
    end
  end

  module RoundCounting
    def round; @round ||= RoundCommand.new(self.runtime).find; end
  end
end
