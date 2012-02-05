
require 'ankit/command'

module Ankit
  class EventTraversingCommand < Command
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
