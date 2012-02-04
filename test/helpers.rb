
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
    def make_runtime
      config = Config.new
      config.repo = HELLO_REPO
      RuntimeWithMockedIO.new(config)
    end
  end
end
