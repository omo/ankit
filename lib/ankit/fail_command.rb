
require 'ankit/card_happening_command'

module Ankit
  class FailCommand < CardHappeningCommand
    available
    EVENT_HAPPENING = :to_failed
  end
end
