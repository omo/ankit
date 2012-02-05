
require 'ankit/card'
require 'ankit/event'
require 'ankit/event_traversing_command'

module Ankit
  class ScoreCommand < EventTraversingCommand
    include CardNaming, EventFormatting
    available

    def execute()
      each_event(to_card_name(args[0])) do |e|
        runtime.stdout.print("#{format_as_score(e)}\n")
      end
    end
  end
end
