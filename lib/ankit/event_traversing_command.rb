
require 'ankit/command'
require 'ankit/card'

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

  # For Command Mixin
  module EventTraversing
    class << self
      include CardNaming
    end

    def self.find_latest_event_for(runtime, path)
      #EventTraversingCommand.new(runtime).to_enum(:each_event, to_card_name(path)).sort_by { |x| x.round }[-1]
      find_latest_event_named(runtime, to_card_name(path))
    end

    def self.find_latest_event_named(runtime, name)
      EventTraversingCommand.new(runtime).to_enum(:each_event, name).sort_by { |x| x.round }[-1]
    end

    def latest_event_for(path) EventTraversing.find_latest_event_for(self.runtime, path); end
  end

end
