
require 'ankit/runtime'
require 'stringio'

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

    def make_config
      config = Config.new
      config.repo = HELLO_REPO
      config.location = "anomone"
      config
    end

    def make_runtime
      RuntimeWithMockedIO.new(make_config)
    end
  end
end
