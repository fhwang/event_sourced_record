require 'test_helper'

class EventSourcedRecord::EventTest < MiniTest::Unit::TestCase
  def test_creation_auto_generates_uuid
    event = SubscriptionEvent.creation.new
    assert event.subscription_uuid
  end

  def test_creation_data_assignment
    event = SubscriptionEvent.creation.new(
      bottles_per_shipment: 1, bottles_purchased: 6, user_id: 999
    )
    assert_equal(999, event.data['user_id'])
    assert_equal(999, event.user_id)
  end

  def test_creation_accessors_on_reload
    event = SubscriptionEvent.creation.new(
      bottles_per_shipment: 1, bottles_purchased: 6, user_id: 999
    )
    event.save!
    event_prime = SubscriptionEvent.find(event.id)
    assert_equal(999, event_prime.user_id)
  end

  def test_creation_reserved_attributes
    event = SubscriptionEvent.creation.new(
      subscription_uuid: 'asdf'
    )
    assert_equal('asdf', event.subscription_uuid)
    assert_nil event.data['subscription_uuid']
  end

  def test_creation_dont_accept_random_attribute
    assert_raises(ActiveRecord::UnknownAttributeError) do 
      SubscriptionEvent.creation.new(foo: 'bar')
    end
    assert_raises(ActiveRecord::UnknownAttributeError) do 
      SubscriptionEvent.change_settings.new(user_id: 123)
    end
  end

  def test_creation_validation_errors
    event = SubscriptionEvent.creation.new
    assert !event.valid?
    assert event.errors[:bottles_per_shipment].include?("can't be blank")
    assert event.errors[:bottles_per_shipment].include?('is not a number')
    assert event.errors[:bottles_purchased].include?("can't be blank")
    assert event.errors[:bottles_purchased].include?('is not a number')
    assert event.errors[:user_id].include?("can't be blank")
  end

  def test_creation_valid
    event = SubscriptionEvent.creation.new(
      bottles_per_shipment: 1, bottles_purchased: 6, user_id: 999
    )
    assert_equal(6, event.bottles_purchased)
    assert event.valid?
  end

  def test_creation_create
    events_before = SubscriptionEvent.count
    SubscriptionEvent.creation.create!(
      bottles_per_shipment: 1, bottles_purchased: 6, user_id: 999
    )
    assert_equal(events_before + 1, SubscriptionEvent.count)
  end

  def test_creation_settable_attributes
    event = SubscriptionEvent.creation.new
    event.bottles_per_shipment = 1
    assert_equal(1, event.bottles_per_shipment)
  end

  def test_change_settings_validation_errors
    event = SubscriptionEvent.change_settings.new
    assert !event.valid?
    assert event.errors[:bottles_per_shipment].include?('is not a number')
  end

  def test_change_settings_valid
    event = SubscriptionEvent.change_settings.new(:bottles_per_shipment => 2)
    assert event.valid?
  end

  def test_new_without_scope
    event = SubscriptionEvent.new(
      event_type: 'creation', bottles_per_shipment: 1, bottles_purchased: 6, 
      user_id: 999
    )
    assert event.valid?
  end

  def test_event_type_required
    event = SubscriptionEvent.new
    assert !event.valid?
    assert event.errors[:event_type].include?("can't be blank")
  end

  def test_event_type_inclusion
    event = SubscriptionEvent.new(event_type: 'wrong')
    assert !event.valid?
    assert event.errors[:event_type].include?("is not a valid event type")
  end

  def test_event_type_unsettable
    event = SubscriptionEvent.creation.new
    assert_raises(EventSourcedRecord::Event::EventTypeImmutableError) do
      event.event_type = 'change_settings'
    end
  end

  def test_events_are_immutable
    event = SubscriptionEvent.creation.create!(
      bottles_per_shipment: 1, bottles_purchased: 6, user_id: 999
    )

    assert_raises(ActiveRecord::ReadOnlyRecord) do
      event.touch
    end
  end

  def test_occurred_at_is_set_if_not_specified
    event = SubscriptionEvent.creation.create!(
      bottles_per_shipment: 1, bottles_purchased: 6, user_id: 999
    )

    assert event.occurred_at
  end

  def test_occurred_at_can_be_specified
    event = SubscriptionEvent.creation.new(
      occurred_at: Time.new(2003, 1, 24, 11, 33), bottles_per_shipment: 1,
      bottles_purchased: 6, user_id: 999
    )

    assert_equal(Time.new(2003, 1, 24, 11, 33), event.occurred_at)
  end

  def test_blank_event_type_is_okay
    event = SubscriptionEvent.blank.new
    assert event.valid?
  end
end
