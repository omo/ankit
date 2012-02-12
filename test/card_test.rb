
require 'ankit/card'
require 'test/unit'

class CardTest < Test::Unit::TestCase
  include Ankit

  def test_parse_empty
    actual = Card.parse(
"""

  
""")
    assert_nil(actual)
  end

  def test_parse_empty_comments
    actual = Card.parse(
"""
#
#
""")
    assert_nil(actual)
  end

  def test_parse_hello
    actual = Card.parse(
"""
O: Hello, how are you?
T: Konichiwa, Genki? 
""")

    assert_equal("Konichiwa, Genki?", actual.translation)
    assert_equal("Hello, how are you?", actual.original)
  end

  def test_name_plain
    actual = Card.parse(
"""
O: Hello, how are you?
T: Konichiwa, Genki? 
""")
    assert_equal("hello-how-are-you", actual.name)
  end

  def test_name_with_a_bracket
    actual = Card.parse(
"""
O: [Hello], How are you?
T: Konichiwa, Genki? 
""")
    assert_equal("hello-how-are-you", actual.name)
  end

  def test_name_with_brackets
    actual = Card.parse(
"""
O: Hello, [How is] your project [going]?
T: Konichiwa, Genki? 
""")
    assert_equal("hello-how-is-your-project-going", actual.name)
  end

  def test_guess_id_with_conflict
    # XXX: will tackle later
  end

  def test_match_hello
    target = Card.new(o: "Hello")
    assert( target.match?("Hello"))
    assert(!target.match?("Bye"))
  end

  def test_match_gracket
    target = Card.new(o: "Hello, [World].")
    assert( target.match?("Hello, World."))
  end
end
