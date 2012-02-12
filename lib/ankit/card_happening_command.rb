
require 'ankit/card'
require 'ankit/command'
require 'ankit/event'
require 'ankit/event_traversing_command'
require 'ankit/round_command'
require 'fileutils'

module Ankit
  module CardHappening
    include CardNaming, EventTraversing, EventFormatting, RoundCounting

    def make_happen(method_name, card_name)
      last = EventTraversing.find_latest_event_for(runtime, card_name) || Event.for_card(card_name, "vanilla", round)
      head = last.send(method_name, Envelope.fresh(round + 1))
      FileUtils.touch(runtime.config.primary_journal)
      open(runtime.config.primary_journal, "a") { |f| f.write("#{head.to_json}\n") }
      head
    end
  end

  class CardHappeningCommand < Command
    include EventFormatting, CardHappening

    def execute()
      head = make_happen(self.class::EVENT_HAPPENING, to_card_name(args[0]))
      runtime.stdout.print("#{format_as_score(head)}\n")
    end
  end
end
