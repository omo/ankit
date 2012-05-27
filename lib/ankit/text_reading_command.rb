
require 'ankit/command'
require 'tempfile'
require 'fileutils'

module Ankit
  class TextReadingCommand < Command
    define_options do |spec, options|
      spec.on("-i", "--stdin") { options[:stdin] = true }
      spec.on("-e", "--editor EDITOR") { |editor| options[:editor] = editor }
    end

    def ask_edit(template)
      f = Tempfile.new('toadd')
      begin
        f.write(template)
        f.flush
        system(options[:editor] + " " + f.path)
        FileUtils.copy(f.path, self.runtime.config.editor_backup)
        open(self.runtime.config.editor_backup) { |f| f.read }
      ensure
        f.close
      end
    end

    def each_text(template="", &block)
      if options[:stdin]
        block.call(runtime.stdin.read)
      elsif options[:editor]
        block.call(ask_edit(template))
      else
        args.each { |name| open(name) { |f| block.call(f.read) } }
      end
    end

    def validate_options
      raise BadOptions, "--stdin cannot have any fileame" if options[:stdin] and not args.empty?
      raise BadOptions, "--editor cannot have any fileame" if options[:editor] and not args.empty?
      raise BadOptions, "need a fileame" if not (options[:stdin] or options[:editor]) and args.empty?
    end
  end
end
