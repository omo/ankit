
require 'ankit/command'
require 'ankit/runtime'

require 'test/unit'
require 'fileutils'
require 'tmpdir'

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

class FindTest < Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper

  def test_hello
    target = make_runtime
    target.dispatch(["find", "vanilla-please", "hello", "no-such-card"])
    assert_equal(target.stdout.string.split, 
                 [repo_data_at("cards/foo/vanilla-please.card"),
                  repo_data_at("cards/foo/hello.card")])
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
    target.dispatch(["name", test_data_at("hello_card.card"), test_data_at("bye_card.card")])
    assert_equal(target.stdout.string.split.map(&:strip), ["hello-world", "bye-universe"])
  end
end

class ScoreTest < Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper

  def test_each_event
    target = ScoreCommand.new(make_runtime, [])
    all = target.to_enum(:each_event).to_a
    assert_equal(all.size, 4)
    assert_equal(all[0].class, Event)
    assert_equal(target.to_enum(:each_event, "hello").to_a.size, 2)
  end

  def test_hello
    target = make_runtime
    target.dispatch(["score", repo_data_at("to_cards/foo/hello.card")])
    assert_equal(2, target.stdout.string.split("\n").map(&:strip).size)
  end
end

class AddTest < Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper

  THE_TEXT = "O:There is no Frigate like a Book\n"
  THE_NAME = "there-is-no-frigate-like-a-book.card"

  def assert_written(runtime, paths)
    lines = runtime.stdout.string.split("\n").map(&:strip)
    assert_equal(paths.size, lines.size)
    lines.zip(paths).each do |line, path|
      assert_equal(path, line)
      assert(File.file?(path))
    end
  end
  
  def test_hello_stdin
    with_runtime_on_temp_repo do |target|
      target.stdin.string << THE_TEXT
      target.dispatch(["add", "--stdin"])
      assert_written(target, [File.join(target.config.card_paths[0], THE_NAME)])
    end
  end

  def test_hello_stdin_dir
    with_runtime_on_temp_repo do |target|
      target.stdin.string << THE_TEXT
      dst_dir = target.config.card_search_paths[1]
      target.dispatch(["add", "--stdin", "--dir", dst_dir])
      assert_written(target, [File.join(dst_dir, THE_NAME)])
    end
  end

  def test_hello_two_file
    with_runtime_on_temp_repo do |target|
      dst_dir = target.config.card_search_paths[1]
      target.dispatch(["add", test_data_at("hope.card"), test_data_at("luck.card")])
      assert_written(target, [File.join(target.config.card_paths[0], "hope-is-the-thing-with-feathers.card"),
                              File.join(target.config.card_paths[0], "luck-is-not-chance.card")])
    end
  end
end

class ComingTest < Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper
  include Ankit::CardNaming

  def test_name
    with_runtime_on_temp_repo do |target|
      target.dispatch(["coming", "--name"])
      assert_equal(target.stdout.string.split, ["vanilla-please", "bye", "how-are-you", "hello"])
    end
  end

  def test_limit
    with_runtime_on_temp_repo do |target|
      target.dispatch(["coming", "--name", "1"])
      assert_equal(target.stdout.string.split, ["vanilla-please"])
    end
  end

  def test_hello
    with_runtime_on_temp_repo do |target|
      dir = File.join(target.config.repo, "cards/foo")
      target.dispatch(["coming"])
      assert_equal(target.stdout.string.split, 
                   [to_card_path(dir, "vanilla-please"),
                    to_card_path(dir, "hello")])
    end
  end
end
