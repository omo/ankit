
require 'ankit/card'
require 'ankit/text_reading_command'

module Ankit
  CARD_TEMPLATE = <<EOF
O:
T:
EOF

  class AddCommand < TextReadingCommand
    include CardNaming
    available
    define_options do |spec, options| 
      superclass.option_spec.call(spec, options) 
      spec.on("-d", "--dir DIR") { |d| options[:dir] = d }
    end

    def execute()
      validate_options
      each_text(CARD_TEMPLATE.strip) do |text|
        text.split(/\n\n+/).map(&:strip).each do |chunk|
          next if chunk.empty?
          card = Card.parse(chunk)
          next unless card
          # TODO: gaurd ovewrite
          # TODO: guard out-of-path write
          filename = to_card_path(dest_dir, card.name)
          File.open(filename, "w") { |f| f.write(chunk) }
          runtime.stdout.write("#{filename}\n")
        end
      end
    end

    def dest_dir; options[:dir] || runtime.config.primary_card_path; end
  end
end
