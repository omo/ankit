
require 'ankit/runtime'
require 'stringio'
require 'fileutils'

module Ankit
  TEST_DATA_BASE = File.join(File.dirname(__FILE__), "data")
  HELLO_REPO = File.join(TEST_DATA_BASE, "hello_repo")

  class RuntimeWithMockedIO < Runtime
    def initialize(config)
      super
      ["stdin=", "stdout=", "stderr="].each { |m| self.send(m, StringIO.new) }
    end

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

    def with_runtime_on_temp_repo(&block)
      Dir.mktmpdir do |temp_repo|
        block.call(make_runtime(copy_hello_repo_to(temp_repo)))
      end
    end
  end
end
