
require 'ankit/card'
require 'ankit/event'
require 'ankit/event_traversing_command'

module Ankit
  class ScoreCommand < EventTraversingCommand
    include CardNaming, EventFormatting
    available

    define_options do |spec, options| 
      spec.on("-l", "--last") { options[:last] = true }
    end

    def execute()
      args.each do |a|
        list = to_enum(:each_event, to_card_name(a)).to_a
        (options[:last] ? list.sort_by(&:round).reverse.take(1) : list).each do |e|
          runtime.stdout.print("#{format_as_score(e)}\n")
        end
      end
    end
  end
end
