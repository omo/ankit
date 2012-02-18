
require 'ankit/runtime'
require 'test/unit'

class ProgressTest < Test::Unit::TestCase
  include Ankit
  include Ankit::TestHelper
  include Ankit::CardNaming
  include Challenge

  def make_target(runtime)
    Progress.new(runtime, [Slot.new("path1"), Slot.new("path2"), Slot.new("path3")])
  end

  def first_slot_event_of(progress)
    EventTraversing.find_latest_event_for(progress.runtime, progress.slots[0].path)
  end

  def test_fail
    with_runtime_on_temp_repo do |runtime|
      target = make_target(runtime)
      target.fail
      fetched_event = first_slot_event_of(target)
      assert_equal(target.index, 0)
      assert_equal(target.slots[0].rating, :failed)
      assert_equal(target.slots[0].event, fetched_event)
      assert_equal(0, fetched_event.maturity)
      assert(runtime.printed_line.empty?)
    end
  end

  def test_pass
    with_runtime_on_temp_repo do |runtime|
      target = make_target(runtime)
      target.pass
      fetched_event = first_slot_event_of(target)
      assert_equal(target.index, 1)
      assert_equal(target.slots[0].rating, :passed)
      assert_equal(target.slots[0].event, fetched_event)
      assert_equal(1, fetched_event.maturity)
      assert(runtime.printed_line.empty?)
    end
  end

  def test_round_during_progress
    with_runtime_on_temp_repo do |runtime|
      target = make_target(runtime)
      target.pass
      e1 = EventTraversing.find_latest_event_named(runtime, "path1")
      target.pass
      e2 = EventTraversing.find_latest_event_named(runtime, "path2")
      assert_equal(target.this_round, e1.round)
      assert_equal(target.this_round, e2.round)
    end
  end

  def test_fail_then_pass
    with_runtime_on_temp_repo do |runtime|
      target = make_target(runtime)
      target.fail
      target.pass
      fetched_event = first_slot_event_of(target)
      assert_equal(target.index, 1)
      assert_equal(target.slots[0].rating, :failed)
      assert_equal(target.slots[0].event, fetched_event)
      assert_equal(0, fetched_event.maturity)
    end
  end

  def test_indicator
    with_runtime_on_temp_repo do |runtime|
      target = make_target(runtime)
      assert_equal("---", target.indicator)
      target.pass
      assert_equal("o--", target.indicator)
      target.attack
      assert_equal("o*-", target.indicator)
      target.fail
      assert_equal("ox-", target.indicator)
    end
  end

end

