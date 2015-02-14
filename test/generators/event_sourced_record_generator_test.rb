require 'test_helper'

class EventSourcedRecord::EventSourcedRecordGeneratorTest < Rails::Generators::TestCase
  destination 'tmp/event_sourced_record_generator_test'
  setup :prepare_destination
  tests EventSourcedRecord::EventSourcedRecordGenerator

  setup do
    @generate_calls = Hash.new { |h,k| h[k] = [] }
    EventSourcedRecord::EventSourcedRecordGenerator.any_instance.stubs(:generate).with { |name, arg_string|
      @generate_calls[name] << arg_string
    }
    run_generator %w(
      ShampooSubscription
      user_id:integer
      bottles_per_shipment:integer
      bottles_left:integer
    )
  end

  test "calls the event generator" do
    assert @generate_calls['event_sourced_record:event'].include?(
      "shampoo_subscription_event shampoo_subscription_uuid:string:index event_type:string data:text created_at:datetime occurred_at:datetime"
    )
  end

  test "calls the projection generator" do
    assert @generate_calls['event_sourced_record:projection'].include?(
      "shampoo_subscription user_id:integer bottles_per_shipment:integer bottles_left:integer"
    )
  end

  test "calls the calculator generator" do
    assert @generate_calls['event_sourced_record:calculator'].include?(
      "shampoo_subscription_calculator"
    )
  end

  test "creates a rake file" do
    assert_file("lib/tasks/shampoo_subscription.rake") do |contents|
      assert_match(/namespace :shampoo_subscription do/, contents)
      assert_match(
        /ShampooSubscription.all.each do |shampoo_subscription|/, contents
      )
      assert_match(
        /ShampooSubscriptionCalculator.new\(shampoo_subscription\).run.save!/, 
        contents
      )
    end
  end
end
