
require 'ankit/card'
require 'ankit/command'
require 'ankit/event'
require 'ankit/event_traversing_command'
require 'ankit/round_command'
require 'fileutils'

module Ankit
  class CardHappeningCommand < Command
    include CardNaming, EventTraversing, EventFormatting, RoundCounting

    def execute()
      # TODO: file existence check
      name = to_card_name(args[0])
      last = latest_event_for(name) || Event.for_card(name, "vanilla", round)
      head = last.send(self.class::EVENT_HAPPENING, Envelope.fresh(round + 1))
      FileUtils.touch(runtime.config.primary_journal)
      open(runtime.config.primary_journal, "a") { |f| f.write("#{head.to_json}\n") }
      runtime.stdout.print("#{format_as_score(head)}\n")
    end
  end
end
