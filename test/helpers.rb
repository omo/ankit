
require 'ankit/runtime'
require 'stringio'
require 'fileutils'
require 'mocha'

module Ankit
  TEST_DATA_BASE = File.join(File.dirname(__FILE__), "data")
  HELLO_REPO = File.join(TEST_DATA_BASE, "hello_repo")
  VANILLA_REPO = File.join(TEST_DATA_BASE, "vanilla_repo")
  NUMBER_REPO = File.join(TEST_DATA_BASE, "number_repo")
  EMPTY_REPO = File.join(TEST_DATA_BASE, "empty_repo")

  class RuntimeWithMockedIO < Runtime
    def initialize(config)
      super
      supress_io
    end

    def printed_line; self.stdout.string.strip; end
    def printed_lines; self.stdout.string.split("\n").map(&:strip); end

    def self.prepare_default; end
  end

  module TestHelper
    def test_data_at(*args) File.join(TEST_DATA_BASE, *args); end
    def repo_data_at(*args) File.join(HELLO_REPO, *args); end

    def copy_hello_repo_to(dst)
      FileUtils.cp_r(HELLO_REPO, dst)
      File.join(dst, File.basename(HELLO_REPO))
    end

    def make_config(repo_dir=HELLO_REPO)
      config = Config.new
      config.repo = repo_dir
      config.location = "anomone"
      config
    end

    def make_runtime(repo_dir=HELLO_REPO)
      RuntimeWithMockedIO.new(make_config(repo_dir))
    end

    def make_runtime_using(config)
      RuntimeWithMockedIO.new(config)
    end

    def make_vanilla_runtime()
      make_runtime(VANILLA_REPO)
    end

    def with_runtime_on_temp_repo(&block)
      Dir.mktmpdir do |temp_repo|
        block.call(make_runtime(copy_hello_repo_to(temp_repo)))
      end
    end
  end
end
