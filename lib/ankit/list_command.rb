
require 'ankit/command'

module Ankit
  class ListCommand < Command
    available
    define_options do |spec, options|
      spec.on("-d", "--dir", "Lists card search paths") { options[:dir] = true }
    end

    def execute()
      if options[:dir]
        runtime.card_search_paths.each do |p|
          runtime.stdout.print(p, "\n")
        end
      else
        runtime.card_search_paths.each do |p|
          Dir.glob(File.join(p, "*.card")).each do |f|
            runtime.stdout.print(f, "\n")
          end
        end
      end
    end

  end
end
