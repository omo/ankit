
require 'ankit/card_happening_command'

module Ankit
  class FailCommand < CardHappeningCommand
    available
    EVENT_HAPPENING = :to_failed
  end

  module Failing
    include CardHappening
    def make_failed(card_name); make_happen(FailCommand::EVENT_HAPPENING, card_name); end
  end
end
