
require 'ankit/command'
require 'ankit/runtime'
require 'test/unit'

class CommandTest < Test::Unit::TestCase
  include Ankit

  def test_available
    assert(Command::COMMANDS.include?(HelloCommand))
  end

  def test_command_names
    assert_equal(Command.by_name["hello"], HelloCommand)
  end
end

class ListTest <  Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper

  def test_hello
    target = make_runtime
    target.dispatch(["hello"])
    lines = target.stdout.string.split("\n").map(&:strip)
    a_subpath = File.join(HELLO_REPO, "cards", "foo")
    assert(lines.include?("card_search_paths: #{a_subpath}"))
  end

  def test_list
    target = make_runtime
    target.dispatch(["list"])
    lines = target.stdout.string.split
    assert( lines.include?(File.join(HELLO_REPO, "cards", "foo", "hello.card")))
    assert(!lines.include?(File.join(HELLO_REPO, "cards", "foo")))
    not_a_card = File.join(HELLO_REPO, "cards", "foo", "this_is_not_a_card.txt")
    assert( File.file?(not_a_card))
    assert(!lines.include?(not_a_card))
  end
end

class NameTest <  Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper

  def test_bad_options
    assert_raise(BadOptions) do
      target = make_runtime
      target.dispatch(["name", "--stdin", "hello"])
    end

    assert_raise(BadOptions) do
      target = make_runtime
      target.dispatch(["name"])
    end
  end

  def test_stdin
    target = make_runtime
    target.stdin.string << "O: Hello!\n\n"
    target.dispatch(["name", "--stdin"])
    assert_equal(target.stdout.string.strip, "hello")
  end

  def test_hello
    target = make_runtime
    target.dispatch(["name", File.join(TEST_DATA_BASE, "hello_card.card")])
    assert_equal(target.stdout.string.strip, "hello-world")
  end
end
