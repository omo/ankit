
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
    lines = make_runtime.dispatch_then(["hello"]).printed_lines
    a_subpath = File.join(HELLO_REPO, "cards", "foo")
    assert(lines.include?("card_search_paths: #{a_subpath}"))
  end

  def test_list
    lines = make_runtime.dispatch_then(["list"]).printed_lines
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
    assert_equal(make_runtime.dispatch_then(["find", "vanilla-please", "hello", "no-such-card"]).printed_lines, 
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
    assert_equal(target.dispatch_then(["name", "--stdin"]).printed_line, "hello")
  end

  def test_hello
    target = make_runtime
    target.dispatch(["name", test_data_at("hello_card.card"), test_data_at("bye_card.card")])
    assert_equal(target.printed_lines, ["hello-world", "bye-universe"])
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
    assert_equal(2, target.printed_lines.size)
  end
end


class RoundTest < Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper

  def test_hello
    assert_equal(make_runtime.dispatch_then(["round"]).printed_line, "2")
  end
end

class AddTest < Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper

  THE_TEXT = "O:There is no Frigate like a Book\n"
  THE_NAME = "there-is-no-frigate-like-a-book.card"

  def assert_written(runtime, paths)
    assert_equal(paths.size, runtime.printed_lines.size)
    runtime.printed_lines.zip(paths).each do |line, path|
      assert_equal(path, line)
      assert(File.file?(path))
    end
  end
  
  def test_hello_stdin
    with_runtime_on_temp_repo do |target|
      target.stdin.string << THE_TEXT
      assert_written(target.dispatch_then(["add", "--stdin"]),
                     [File.join(target.config.card_paths[0], THE_NAME)])
    end
  end

  def test_hello_stdin_dir
    with_runtime_on_temp_repo do |target|
      target.stdin.string << THE_TEXT
      dst_dir = target.config.card_search_paths[1]
      assert_written(target.dispatch_then(["add", "--stdin", "--dir", dst_dir]),
                     [File.join(dst_dir, THE_NAME)])
    end
  end

  def test_hello_two_file
    with_runtime_on_temp_repo do |target|
      dst_dir = target.config.card_search_paths[1]
      assert_written(target.dispatch_then(["add", test_data_at("hope.card"), test_data_at("luck.card")]),
                     [File.join(target.config.card_paths[0], "hope-is-the-thing-with-feathers.card"),
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
      assert_equal(target.dispatch_then(["coming", "--name"]).printed_lines,
                   ["vanilla-please", "bye", "how-are-you", "hello"])
    end
  end

  def test_limit
    with_runtime_on_temp_repo do |target|
      
      assert_equal(target.dispatch_then(["coming", "--name", "1"]).printed_lines,
                   ["vanilla-please"])
    end
  end

  def test_hello
    with_runtime_on_temp_repo do |target|
      dir = File.join(target.config.repo, "cards/foo")
      assert_equal(target.dispatch_then(["coming"]).printed_lines, 
                   [to_card_path(dir, "vanilla-please"),
                    to_card_path(dir, "hello")])
    end
  end
end

class FailPassTest < Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper
  include Ankit::CardNaming, Ankit::Coming

  VANILLA = "vanilla-please"
  JUNIOR  = "bye"
  MIDDLE  = "how-are-you"
  VINTAGE = "hello"

  def path_for(runtime, name)
    dir = File.join(runtime.config.repo, "cards/foo")
    to_card_path(dir, name)
  end

  def run_test_against(command, card, &block)
    with_runtime_on_temp_repo do |target|
      path = path_for(target, card)
      target.dispatch([command, path])
      assert_equal(target.printed_lines.size, 1)
      events = Coming.list(target)
      block.call(events)
    end
  end

  def test_pass_vanilla
    run_test_against("pass", VANILLA) do |events|
      assert_equal(events[0].name, VANILLA)
      assert_equal(events[0].maturity, 1)
    end
  end

  def test_pass_vintage
    run_test_against("pass", VINTAGE) do |events|
      assert_equal(events.map(&:name), [VANILLA, JUNIOR, MIDDLE, VINTAGE])
    end
  end

  def test_pass_junior
    run_test_against("pass", JUNIOR) do |events|
      assert_equal(events.map(&:name), [VANILLA, MIDDLE, JUNIOR, VINTAGE])
      assert_equal(events[2].maturity, 3)
    end
  end

  def test_fail_vanilla
    run_test_against("fail", VANILLA) do |events|
      assert_equal(events[0].name, VANILLA)
      assert_equal(events[0].maturity, 0)
    end
  end

  def test_fail_vintage
    run_test_against("fail", VINTAGE) do |events|
      assert_equal(events.map(&:name), [VINTAGE, VANILLA, JUNIOR, MIDDLE])
      assert_equal(events[0].maturity, 0)
    end
  end
end

