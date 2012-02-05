
require 'ankit/command'

module Ankit
  class ListCommand < Command
    available

    def execute()
      runtime.card_search_paths.each do |p|
        Dir.glob(File.join(p, "*.card")).each do |f|
          runtime.stdout.print("#{f}\n")
        end
      end
    end
  end
end
