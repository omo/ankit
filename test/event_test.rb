
require 'ankit/event'
require 'test/unit'

class EventTest < Test::Unit::TestCase
  include Ankit

  def setup
    @target = Event.parse('{"envelope":{"at":"2001-02-03T04:05:06+00:00","round":1},' +
                          '"values":{"type":"card","verb":"add","name":"hello","maturity":1}}')
    @next_envelope = Envelope.parse('{"at":"2002-03-04T05:06:07+00:00","round":2}')
  end

  def test_to_passed
    expected = Event.new(@next_envelope, JSON.parse('{"type":"card","verb":"passed","name":"hello","maturity":2}'))
    actual = @target.to_passed(@next_envelope)
    assert_equal(actual, expected)
  end

  def test_to_failed
    expected = Event.new(@next_envelope, JSON.parse('{"type":"card","verb":"failed","name":"hello","maturity":0}'))
    actual = @target.to_failed(@next_envelope)
    assert_equal(actual, expected)
  end

  def test_next_round
    assert_equal(@target.next_round, 3)
  end
end