require 'rails'
require 'rails/test_help'
require 'rails/generators/test_case'
require 'pry'
require 'mocha/test_unit'
$: << 'lib'
require 'event_sourced_record'
require 'generators/event_sourced_record/event_sourced_record_generator'
require 'generators/event_sourced_record/calculator_generator'
require 'generators/event_sourced_record/event_generator'
require 'generators/event_sourced_record/observer_generator'
require 'generators/event_sourced_record/projection_generator'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3', :database => 'tmp/test.sqlite3'
)

silence_stream(STDOUT) do
  ActiveRecord::Schema.define do
    create_table "shipments", force: true do |t|
      t.integer  "subscription_id"
      t.integer  "num_bottles"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    create_table 'subscription_events', :force => true do |t|
      t.string   "subscription_uuid"
      t.string   "event_type"
      t.text     "data"
      t.datetime "created_at"
    end

    create_table "subscriptions", force: true do |t|
      t.integer "user_id"
      t.integer "bottles_per_shipment"
      t.integer "bottles_left"
      t.string  "uuid"
    end
  end
end

class Shipment < ActiveRecord::Base
end

class SubscriptionEvent < ActiveRecord::Base
  include EventSourcedRecord::Event

  event_type :creation do
    attributes :bottles_per_shipment, :bottles_purchased, :user_id

    validates :bottles_per_shipment, presence: true, numericality: true
    validates :bottles_purchased, presence: true, numericality: true
    validates :user_id, presence: true
  end

  event_type :change_settings do
    attributes :bottles_per_shipment

    validates :bottles_per_shipment, numericality: true
  end
end

class Subscription < ActiveRecord::Base
  has_many :subscription_events

  validates :uuid, uniqueness: true
end

class SubscriptionCalculator < EventSourcedRecord::Calculator
  events :subscription_events, :shipments

  def advance_creation(event)
    @subscription.bottles_per_shipment = event.bottles_per_shipment
    @subscription.bottles_left = event.bottles_purchased
  end

  def advance_shipment(shipment)
    @subscription.bottles_left -= shipment.num_bottles
  end
end
