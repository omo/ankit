
require 'ankit/card'
require 'ankit/command'

module Ankit
  class ListCommand < Command
    include CardNaming
    available

    def execute()
      each_card { |f| runtime.stdout.print("#{f}\n") }
    end

    def each_card(&block)
      runtime.config.card_search_paths.each do |p|
        Dir.glob(card_wildcard_for(p)).each do |f|
          block.call(f)
        end
      end
    end

    def each_card_name(&block)
      each_card { |path| block.call(to_card_name(path)) }
    end
  end
end
