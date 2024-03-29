
require 'ankit/runtime'
require 'test/unit'
require 'helpers'

class ConfigTest < Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper

  def test_defaults
    config = Config.new
    config.location = "hello"
    assert_equal(File.expand_path("~/.ankit.d/hello.journal"), config.primary_journal)
    assert_equal([File.expand_path("~/.ankit.d/cards")], config.card_paths)
  end

  def test_card_search_paths
    target = make_config
    assert_equal(["#{HELLO_REPO}/cards",
                  "#{HELLO_REPO}/cards/bar",
                  "#{HELLO_REPO}/cards/foo"],
                 target.card_search_paths)
  end

  def test_journals
    target = make_config
    assert_equal(["#{HELLO_REPO}/anemone.journal",
                  "#{HELLO_REPO}/baobab.journal"],
                 target.journals)
  end

  def test_open
    config = Config.open(File.join(TEST_DATA_BASE, "hello_config.rb"))
    assert_equal("hello_repo/hello.journal", config.primary_journal)
    assert_equal(["hello_repo/cards", "hello_repo/more"], config.card_paths)
  end

end

class RuntimeTest < Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper

  def test_split_subcommand
    assert_equal({global: [], subcommand: ["hello", "foo", "bar"]},
                 Runtime.split_subcommand(["hello", "foo", "bar"]))
    assert_equal({global: ["--config", "foo.txt"], subcommand: ["hello", "foo", "bar"]},
                 Runtime.split_subcommand(["--config", "foo.txt", "hello", "foo", "bar"]))
    assert_equal({global: [], subcommand: []},
                 Runtime.split_subcommand([]))
  end

  def test_run
    actual = RuntimeWithMockedIO.run(["--config", File.join(TEST_DATA_BASE, "hello_config.rb"), "hello"])
    assert_equal(actual.class, HelloCommand)
    assert_equal(File.basename(actual.runtime.config.repo), "hello_repo")
  end
end
