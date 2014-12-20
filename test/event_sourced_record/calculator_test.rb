require 'test_helper'

class EventSourcedRecord::CalculatorTest < MiniTest::Unit::TestCase
  def setup
    @event = SubscriptionEvent.creation.create!(
      bottles_per_shipment: 1, bottles_purchased: 6, user_id: 12345
    )
    assert @event.subscription_uuid
  end
  
  def test_run_when_the_sourced_record_doesnt_exist
    calculator = SubscriptionCalculator.new(@event.subscription_uuid)
    subscription = calculator.run
    assert_equal(1, subscription.bottles_per_shipment)
    assert_equal(6, subscription.bottles_left)
    assert_equal(@event.subscription_uuid, subscription.uuid)
    assert !subscription.persisted? 
  end

  def test_run_when_the_sourced_record_already_exists
    subscription = Subscription.create!(uuid: @event.subscription_uuid)
    calculator = SubscriptionCalculator.new(@event.subscription_uuid)
    subscription_prime = calculator.run
    assert_equal(1, subscription_prime.bottles_per_shipment)
    assert_equal(6, subscription_prime.bottles_left)
    assert_equal(@event.subscription_uuid, subscription.uuid)
    assert_equal(subscription.id, subscription_prime.id)
  end

  def test_run_and_save_when_the_sourced_record_doesnt_exist
    calculator = SubscriptionCalculator.new(@event.subscription_uuid)
    subscription = calculator.run.tap(&:save!)
    assert_equal(1, subscription.bottles_per_shipment)
    assert_equal(6, subscription.bottles_left)
    assert_equal(@event.subscription_uuid, subscription.uuid)
    assert subscription.persisted? 
  end

  def test_run_and_save_when_the_sourced_record_already_exists
    subscription = Subscription.create!(uuid: @event.subscription_uuid)
    subscription_count = Subscription.count
    calculator = SubscriptionCalculator.new(@event.subscription_uuid)
    subscription_prime = calculator.run.tap(&:save!)
    assert_equal(subscription_count, Subscription.count)
    assert_equal(1, subscription_prime.bottles_per_shipment)
    assert_equal(6, subscription_prime.bottles_left)
    assert_equal(@event.subscription_uuid, subscription.uuid)
    assert_equal(subscription.id, subscription_prime.id)
  end

  def test_run_with_a_different_event_class
    event = SubscriptionEvent.creation.create!(
      bottles_per_shipment: 1, bottles_purchased: 6, user_id: 99999
    )
    subscription = SubscriptionCalculator.new(event.subscription_uuid).run.tap(&:save!)
    assert_equal(6, subscription.bottles_left)
    Shipment.create!(subscription_id: subscription.id, num_bottles: 3)
    SubscriptionCalculator.new(event.subscription_uuid).run.tap(&:save!)
    subscription.reload
    assert_equal(3, subscription.bottles_left)
  end

  def test_initialize_by_projection_or_id_or_event_or_associated_event
    event = SubscriptionEvent.creation.create!(
      bottles_per_shipment: 1, bottles_purchased: 6, user_id: 99999
    )
    subscription = SubscriptionCalculator.new(event).run.tap(&:save!)
    shipment = Shipment.create!(
      subscription_id: subscription.id, num_bottles: 3
    )
    lookups = [subscription, subscription.id, event, shipment]
    lookups.each do |lookup|
      calculator = SubscriptionCalculator.new(lookup)
      assert_equal(
        subscription, calculator.run,
        "Can't find subscription with lookup #{lookup.inspect}"
      )
    end
  end

  def test_run_modifies_a_different_instance
    event = SubscriptionEvent.creation.create!(
      bottles_per_shipment: 1, bottles_purchased: 6, user_id: 99999
    )
    subscription = SubscriptionCalculator.new(event).run.tap(&:save!)
    subscription.bottles_left = 999
    SubscriptionCalculator.new(subscription).run
    assert_equal(999, subscription.bottles_left)
  end

  def test_last_event_time
    event = SubscriptionEvent.creation.create!(
      bottles_per_shipment: 1, bottles_purchased: 6, user_id: 99999,
      created_at: Time.utc(2015,1,1)
    )
    subscription = SubscriptionCalculator.new(event).run.tap(&:save!)
    Shipment.create!(
      subscription_id: subscription.id, num_bottles: 3, 
      created_at: Time.utc(2015,1,4,12)
    )
    calculator = SubscriptionCalculator.new(subscription)
    result1 = calculator.run(last_event_time: Date.new(2015,1,1))
    assert_equal(6, result1.bottles_left)
    result2 = calculator.run(last_event_time: Time.utc(2015,1,4))
    assert_equal(6, result2.bottles_left)
    result3 = calculator.run(last_event_time: Time.utc(2015,1,5))
    assert_equal(3, result3.bottles_left)
    result4 = calculator.run(last_event_time: Date.new(2015,1,5))
    assert_equal(3, result4.bottles_left)
  end
end
