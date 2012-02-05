
require 'ankit/text_reading_command'

module Ankit
  class NameCommand < TextReadingCommand
    available
    define_options { |s, o| superclass.option_spec.call(s, o) }

    def execute()
      validate_options
      each_text do |text|
        runtime.stdout.print("#{Card.parse(text).name}\n")
      end
    end
  end
end
