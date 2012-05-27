
require 'optparse'
require 'fileutils'
require 'highline'
require 'ankit/command'
require 'ankit/errors'
require 'ankit/add_command'
require 'ankit/challenge_command'
require 'ankit/coming_command'
require 'ankit/fail_command'
require 'ankit/find_command'
require 'ankit/hello_command'
require 'ankit/list_command'
require 'ankit/name_command'
require 'ankit/pass_command'
require 'ankit/round_command'
require 'ankit/score_command'

module Ankit

  class Config
    DEFAULT_PATH = File.expand_path("~/.ankit")

    attr_writer :repo, :location, :card_paths, :primary_card_path, :challenge_limit

    def repo; @repo ||= File.expand_path("~/.ankit.d"); end
    def location; @location ||= `hostname`.strip; end
    def card_paths; @card_paths ||= [File.join(repo, "cards")]; end
    def primary_card_path; @primary_card_path ||= card_paths[0]; end
    def challenge_limit; @challenge_limit ||= 50; end

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

    def editor_backup
      File.join(self.repo, "last_edited.txt")
    end

    def self.open(path)
      config = self.new
      config.instance_eval(File.open(path){ |f| f.read })
      config
    end

    def self.prepare_default
      FileUtils.touch([DEFAULT_PATH]) # TODO: Give same example settings.
      plain = Config.open(DEFAULT_PATH)
      (plain.card_paths + [plain.repo]).each { |p| FileUtils.mkdir_p(p) }
      FileUtils.touch([plain.primary_journal])
      STDOUT.print("Prepared the default setting. You can edit #{DEFAULT_PATH}\n")
    end
  end

  class Runtime
    attr_writer :line, :stdin, :stdout, :stderr
    attr_reader :config

    def line; @line ||= HighLine.new; end
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
        r.dispatch([ChallengeCommand.command_name])
      else
        r.dispatch(splitted[:subcommand])
      end
    rescue ExpectedFatalError
      print("Error:", $!.message, "\n")
      exit(1)
    end
    
    def initialize(config)
      @config = config
    end

    def make_command(args)
      name = args.shift
      Command.by_name[name].new(self, args)
    end

    def dispatch(args)
      command = make_command(args)
      command.execute()
      command
    end

    # To encourage one-liner
    def dispatch_then(args)
      dispatch(args)
      self
    end

    def supress_io
      saved = [@stdin, @stdout, @stderr]
      ["stdin=", "stdout=", "stderr="].each { |m| self.send(m, StringIO.new) }
      saved
    end

    def clear_screen
      w = HighLine::SystemExtensions.terminal_size[1]
      stdout.print("\033[#{w}D")
      stdout.print("\033[2J")
      h = HighLine::SystemExtensions.terminal_size[0]
      stdout.print("\033[#{h}A")
    end

    def unsupress_io(saved)
      @stdin, @stdout, @stderr =  saved
    end

    def with_supressing_io(&block)
      saved = supress_io
      begin
        block.call
      ensure
        unsupress_io(saved)
      end
    end
  end
end
