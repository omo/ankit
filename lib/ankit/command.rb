
require 'optparse'

module Ankit
  class Command
    attr_reader :runtime, :options, :args

    COMMANDS = []

    def self.available
      COMMANDS.push(self)
    end

    def self.by_name
      COMMANDS.inject({}) do |a, cls|
        name = /(.*)\:\:(\w+)Command/.match(cls.name).to_a[-1].downcase
        a[name] = cls
        a
      end
    end

    def self.define_options(&block) @option_spec = block end
    def self.option_spec; @option_spec; end

    def initialize(runtime, args)
      @runtime = runtime
      @options = {}
      @args = OptionParser.new do |spec|
        self.class.option_spec.call(spec, @options) if self.class.option_spec
      end.parse(args)
    end
  end

  class HelloCommand < Command
    available
    def execute; end
  end
end
