require 'test_helper'

class EventSourcedRecord::EventGeneratorTest < Rails::Generators::TestCase
  destination 'tmp/event_generator_test'
  setup :prepare_destination
  tests EventSourcedRecord::EventGenerator

  setup do
    @generate_calls = Hash.new { |h,k| h[k] = [] }
    EventSourcedRecord::EventGenerator.any_instance.stubs(:generate).with { |name, arg_string|
      @generate_calls[name] << arg_string
    }
    run_generator %w(
      subscription_event
      subscription_uuid:string:index
      event_type:string
      data:text
      created_at:datetime
    )
  end

  test "creates a migration for the event class" do
    assert @generate_calls['migration'].include?(
      "create_subscription_events subscription_uuid:string:index event_type:string data:text created_at:datetime"
    )
  end

  test "creates a model for the event class" do
    assert_file("app/models/subscription_event.rb") do |contents|
      assert_match(/class SubscriptionEvent < ActiveRecord::Base/, contents)
      assert_match(/include EventSourcedRecord::Event/, contents)
      assert_match(/event_type :creation do/, contents)
    end
  end
end
