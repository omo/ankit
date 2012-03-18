
require 'ankit/card'
require 'ankit/text_reading_command'

module Ankit
  class AddCommand < TextReadingCommand
    include CardNaming
    available
    define_options do |spec, options| 
      superclass.option_spec.call(spec, options) 
      spec.on("-d", "--dir DIR") { |d| options[:dir] = d }
    end

    def execute()
      validate_options
      each_text do |text|
        text.split(/\n\n+/).each do |chunk|
          card = Card.parse(chunk)
          # TODO: gaurd ovewrite
          # TODO: guard out-of-path write
          filename = to_card_path(dest_dir, card.name)
          File.open(filename, "w") { |f| f.write(text) }
          runtime.stdout.write("#{filename}\n")
        end
      end
    end

    def dest_dir; options[:dir] || runtime.config.card_paths[0]; end
  end
end
