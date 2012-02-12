
require 'ankit/command'
require 'ankit/event_traversing_command'
require 'ankit/list_command'
require 'ankit/round_command'
require 'ankit/event'

module Ankit
  class ComingCommand < Command
    include RoundCounting

    available
    define_options do |spec, options| 
      spec.on("-n", "--name") { options[:name] = true }
    end

    DEFAULT_COUNT = 6

    def find_command; @find_command ||= FindCommand.new(runtime); end

    def execute()
      toprint = to_enum(options[:name] ? :each_coming_names : :each_coming_paths)
      toprint.take(0 <= count ? count : name_to_events.size).each { |i| runtime.stdout.print("#{i}\n") }
    end

    def each_coming_names(&block); each_coming_events { |e| block.call(e.name) }; end

    def each_coming_paths(&block)
      each_coming_events do |event|
        found = self.find_command.path_for(event.name)
        block.call(found) if found
      end
    end

    def each_coming_events(&block)
      name_to_events.values.sort_by(&:next_round).each(&block)
    end

    def each_existing_events(&block)
      name_to_existing_events.values.sort_by(&:next_round).each(&block)
    end

    def name_to_events
      @name_to_events ||= compute_name_to_events
    end

    def name_to_existing_events
      EventTraversingCommand.new(runtime).to_enum(:each_event).reduce({}) do |a, e|
        existing = a[e.name]
        a[e.name] = e if existing.nil? or existing.round < e.round
        a
      end
    end

    def name_to_vanilla_events
      vanilla_round = round - 1 # forces to come upfront.
      ListCommand.new(runtime).to_enum(:each_card_name).reduce({}) do |a, name|
        a[name] = Event.for_card(name, "vanilla", Envelope.fresh(vanilla_round))
        a
      end
    end

    private

    def compute_name_to_events
      existing = name_to_existing_events
      vanilla = name_to_vanilla_events
      vanilla.merge(existing)
    end

    def count
      args.empty? ? DEFAULT_COUNT : args[0].to_i
    end
  end

  module Coming
    def self.coming_events(runtime)
      ComingCommand.new(runtime).to_enum(:each_coming_events).to_a
    end

    def self.coming_paths(runtime)
      ComingCommand.new(runtime).to_enum(:each_coming_paths).to_a
    end

    def self.existing_events(runtime)
      ComingCommand.new(runtime).to_enum(:each_existing_events).to_a
    end
  end

end
