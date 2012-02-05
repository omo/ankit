
require 'optparse'
require 'fileutils'
require 'ankit/command'
require 'ankit/hello_command'
require 'ankit/list_command'
require 'ankit/name_command'
require 'ankit/score_command'

module Ankit

  class Config
    DEFAULT_PATH = File.expand_path("~/.ankit")

    attr_writer :repo, :location, :card_paths

    def repo; @repo ||= File.expand_path("~/.ankit.d"); end
    def location; @location ||= `hostname`.strip; end
    def card_paths; @card_paths ||= [File.join(repo, "cards")]; end

    # Computed parameters
    def primary_journal
      File.join(repo, "#{location}.journal")
    end

    def journals
      Dir.glob(File.join(repo, "*.journal")).sort
    end

    def card_search_paths
      paths = self.card_paths.dup
      self.card_paths.each do |path|
        Dir.glob(File.join(path, "*")).each do |f|
          paths.push(f) if File.directory?(f)
        end
      end

      paths.sort
    end


    def self.open(path)
      config = self.new
      config.instance_eval(File.open(path){ |f| f.read })
      config
    end

    def self.touch(path)
      File.open(path, "w") { |f| f.write("") } unless File.file?(path)
    end

    def self.prepare_default
      touch(DEFAULT_PATH) # TODO: Give same example settings.
      plain = Config.open(DEFAULT_PATH)
      (plain.card_paths + [plain.repo]).each { |p| FileUtils.mkdir_p(p) }
      touch(plain.primary_journal)
      STDOUT.print("Prepared the default setting. You can edit #{DEFAULT_PATH}\n")
    end

    def make_ready(options)
    end
  end

  class Runtime
    attr_writer :stdin, :stdout, :stderr
    attr_reader :config

    def stdin; @stdin ||= STDIN; end
    def stdout; @stdout ||= STDOUT; end
    def stderr; @stderr ||= STDERR; end

    def self.split_subcommand(args)
      names = Command.by_name.keys
      i = args.find_index { |a| names.include?(a) }
      unless i.nil?
        { global: args[0 ... i], subcommand: args[i .. -1] }
      else
        { global: [], subcommand: [] }
      end
    end

    def self.parse_options(args)
      options = {}
      OptionParser.new do |spec|
        spec.on("-c", "--config FILE", "Specifies config file") { |file| options[:config] = file }
      end.parse(args)

      options[:noconf]   = options[:config].nil?
      options[:config] ||= Config::DEFAULT_PATH
      options
    end

    def self.setup(args)
      options = self.parse_options(args)
      Config.prepare_default if options[:noconf] and not File.exist?(Config::DEFAULT_PATH)
      r = self.new(Config.open(options[:config]))
    end
    
    def self.run(args)
      splitted = self.split_subcommand(args)
      r = self.setup(splitted[:global])
      if splitted[:subcommand].empty?
        # TODO: show help
      else
        r.dispatch(splitted[:subcommand])
      end
    end
    
    def initialize(config)
      @config = config
    end

    def dispatch(args)
      name = args.shift
      command = Command.by_name[name].new(self, args)
      command.execute()
      command
    end
  end
end
