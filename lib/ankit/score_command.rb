
require 'ankit/card'
require 'ankit/event_traversing_command'

module Ankit
  class ScoreCommand < EventTraversingCommand
    include CardNaming
    available

    def execute()
      each_event(to_card_name(args[0])) do |e|
        runtime.stdout.print("round:#{e.verb}, #{e.round}\n")
      end
    end
  end
end
