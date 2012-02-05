
require 'ankit/command'

module Ankit
  class TextReadingCommand < Command
    define_options do |spec, options|
      spec.on("-i", "--stdin") { options[:stdin] = true }
    end

    def each_text(&block)
      if options[:stdin]
        block.call(runtime.stdin.read)
      else
        args.each { |name| open(name) { |f| block.call(f.read) } }
      end
    end

    def validate_options
      raise BadOptions, "--stdin cannot have any fileame" if options[:stdin] and not args.empty?
      raise BadOptions, "need a fileame" if not options[:stdin] and args.empty?
    end
  end
end
