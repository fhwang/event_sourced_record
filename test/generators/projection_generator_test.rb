require 'test_helper'

class EventSourcedRecord::ProjectionGeneratorTest < Rails::Generators::TestCase
  destination 'tmp/projection_generator_test'
  setup :prepare_destination
  tests EventSourcedRecord::ProjectionGenerator

  setup do
    @generate_calls = Hash.new { |h,k| h[k] = [] }
    EventSourcedRecord::ProjectionGenerator.any_instance.stubs(:generate).with { |name, arg_string|
      @generate_calls[name] << arg_string
    }
    run_generator %w(
      subscription
      user_id:integer
      bottles_per_shipment:integer
      bottles_left:integer
    )
  end

  test "creates a migration for the projection class" do
    assert(
      @generate_calls['migration'].include?(
        "create_subscriptions user_id:integer bottles_per_shipment:integer bottles_left:integer uuid:string:uniq"
      ),
      @generate_calls.inspect
    )
  end

  test "creates a model for the projection class" do
    assert_file("app/models/subscription.rb") do |contents|
      assert_match(/class Subscription < ActiveRecord::Base/, contents)
      assert_match(/validates :uuid, uniqueness: true/, contents)
    end
  end
end
