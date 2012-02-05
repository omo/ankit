
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

    DEFAULT_COUNT = -1

    def execute()
      sorted_names = each_sorted_events.map(&:name)
      toprint = options[:name] ? sorted_names : FindCommand.new(runtime, sorted_names).to_enum(:each_card_path)
      toprint.take(0 <= count ? count : sorted_names.size).each { |i| runtime.stdout.print("#{i}\n") }
    end

    def each_sorted_events(&block)
      name_to_events.values.sort_by(&:next_round).each(&block)
    end

    def name_to_events
      ret = {}
      # TODO: recent-to-past order would be better.
      EventTraversingCommand.new(runtime).to_enum(:each_event).reduce(ret) do |a, e|
        existing = a[e.name]
        a[e.name] = e if existing.nil? or existing.round < e.round
        a
      end

      ListCommand.new(runtime).to_enum(:each_card_name).reduce(ret) do |a, name|
        existing = a[name]
        a[name] = Event.for_card(name, "vanilla", Envelope.fresh(round)) if existing.nil?
        a
      end

      ret
    end

    def count
      args.empty? ? DEFAULT_COUNT : args[0].to_i
    end
  end

  module Coming
    def self.list(runtime)
      ComingCommand.new(runtime).to_enum(:each_sorted_events).to_a
    end
  end

end
