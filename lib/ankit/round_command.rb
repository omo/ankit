
require 'ankit/card'
require 'ankit/event_traversing_command'

module Ankit
  class RoundCommand < EventTraversingCommand
    available

    def execute()
      runtime.stdout.print("#{find}\n")
    end

    def find
      to_enum(:each_event).max_by(&:round).round
    end
  end

  module RoundCounting
    def round; @round ||= RoundCommand.new(self.runtime).find; end
  end
end
