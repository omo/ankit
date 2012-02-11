
require 'ankit/card'
require 'ankit/command'
require 'ankit/find_command'

module Ankit
  class FindCommand < Command
    include CardNaming
    available

    def execute()
      each_path { |f| runtime.stdout.print("#{f}\n") }
    end

    def each_path(&block)
      names.each do |n|
        found = path_for(n)
        block.call(found) if found
      end
    end

    def path_for(name)
      found_in = runtime.config.card_search_paths.find do |p|
        File.file?(to_card_path(p, name))
      end

      found_in ? to_card_path(found_in, name) : nil
    end

    def names; args; end
  end

  module Finding
    def find_paths(runtime, names)
      FindCommand.new(runtime, names).to_enum(:each_path).to_a
    end
  end
end
