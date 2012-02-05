
require 'ankit/command'

module Ankit
  class ScoreCommand < Command
    available

    def execute()
      each_event(File.basename(args[0], ".card")) do |e|
        runtime.stdout.print("round:#{e.verb}, #{e.round}\n")
      end
    end

    def each_event(name=nil, &block)
      runtime.config.journals.each do |j|
        open(j) do |f|
          f.each_line do |line|
            event = Event.parse(line)
            block.call(event) if nil == name or event.name == name
          end
        end
      end
    end
  end
end
