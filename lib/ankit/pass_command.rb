
require 'ankit/card_happening_command'

module Ankit
  class PassCommand < CardHappeningCommand
    available
    EVENT_HAPPENING = :to_passed
  end
end
