
require 'ankit/text_reading_command'

module Ankit
  class AddCommand < TextReadingCommand
    available
    define_options do |spec, options| 
      superclass.option_spec.call(spec, options) 
      spec.on("-d", "--dir DIR") { |d| options[:dir] = d }
    end

    def execute()
      validate_options
      each_text do |text|
        card = Card.parse(text)
        # TODO: gaurd ovewrite
        # TODO: guard out-of-path write
        filename = File.join(dest_dir, "#{card.name}.card")
        File.open(filename, "w") { |f| f.write(text) }
        runtime.stdout.write("#{filename}\n")
      end
    end

    def dest_dir; options[:dir] || runtime.config.card_paths[0]; end
  end
end
