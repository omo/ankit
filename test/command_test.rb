
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

  def test_list_dir
    target = make_runtime
    target.dispatch(["list", "--dir"])
    lines = target.stdout.string.split
    assert_equal(3, lines.size)
    assert(lines.include?(File.join(HELLO_REPO, "cards", "foo")))
  end
end
