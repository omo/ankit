
require 'ankit/command'

module Ankit
  class HelloCommand < Command
    available

    def execute()
      indent = "  "
      runtime.stdout.print("\n")
      runtime.stdout.print(indent, "repo: #{runtime.config.repo}\n")
      runtime.stdout.print(indent, "primary: #{runtime.config.primary_journal}\n")
      runtime.stdout.print(indent, "location: #{runtime.config.location}\n")

      runtime.config.card_search_paths.each do |p|
        runtime.stdout.print(indent, "card_search_paths: #{p}\n")
      end

      runtime.stdout.print("\n")
    end
  end
end
