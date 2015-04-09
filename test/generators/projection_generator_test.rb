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
    ar_major_version = ActiveRecord::VERSION::MAJOR
    if ar_major_version >= 4
      assert(
        @generate_calls['migration'].include?(
          "create_subscriptions user_id:integer bottles_per_shipment:integer bottles_left:integer uuid:string:uniq created_at:datetime updated_at:datetime"
        ),
        @generate_calls.inspect
      )
    else
      assert_migration("db/migrate/create_subscriptions.rb") do |contents|
        assert_match(/t.integer :user_id/, contents)
        assert_match(/t.string :uuid/, contents)
        assert_match(/t.timestamps/, contents)
        assert_match(/add_index :\w*, :uuid, :unique => true/, contents)
      end
    end
  end

  test "creates a model for the projection class" do
    assert_file("app/models/subscription.rb") do |contents|
      assert_match(/class Subscription < ActiveRecord::Base/, contents)
      assert_match(/validates :uuid, uniqueness: true/, contents)
      assert_no_match(/attr_accessible :bottles_left/, contents)
      assert_match(/has_many :events,/, contents)
      assert_match(/class_name: 'SubscriptionEvent',/, contents)
      assert_match(/foreign_key: 'subscription_uuid',/, contents)
      assert_match(/primary_key: 'uuid'/, contents)
    end
  end
end
