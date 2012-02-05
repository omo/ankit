
require 'ankit/card'
require 'ankit/command'
require 'ankit/find_command'

module Ankit
  class FindCommand < Command
    include CardNaming
    available

    def execute()
      each_card_path { |f| runtime.stdout.print("#{f}\n") }
    end

    def each_card_path(&block)
      names.each do |n|
        begin
          runtime.config.card_search_paths.each do |p|
            path = to_card_path(p, n)
            if File.file?(path)
              block.call(path) 
              raise StopIteration
            end
          end
        rescue StopIteration
          # try next name
        end
      end
    end

    def names; args; end
  end
end
