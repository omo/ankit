
require 'ankit/command'

module Ankit
  class NameCommand < Command
    available
    define_options do |spec, options|
      spec.on("-i", "--stdin") { options[:stdin] = true }
    end

    def execute()
      validate_options
      runtime.stdout.print("#{Card.parse(read).name}\n")
    end

    private

    def read() options[:stdin] ? runtime.stdin.read : open(args[0]) { |f| f.read }; end
    def validate_options
      raise BadOptions, "--stdin cannot have any fileame" if options[:stdin] and not args.empty?
      raise BadOptions, "need a fileame" if not options[:stdin] and args.empty?
    end
  end
end
