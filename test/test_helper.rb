require 'rails'
require 'rails/test_help'
require 'rails/generators/test_case'
require 'pry'
require 'mocha/test_unit'
#require 'rails/generators/active_record'
$: << 'lib'
require 'event_sourced_record'
require 'generators/event_sourced_record'
#require 'generators/event_sourced_record/event_sourced_record_generator'
#require 'generators/event_sourced_record/calculator_generator'
#require 'generators/event_sourced_record/event_generator'
#require 'generators/event_sourced_record/observer_generator'
#require 'generators/event_sourced_record/projection_generator'
require 'active_record'

def test_db_dir
  './tmp'
end

Dir.mkdir test_db_dir unless Dir.exists? test_db_dir

ActiveRecord::Base.establish_connection(
  :adapter => 'sqlite3', :database => "#{test_db_dir}/test.sqlite3"
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
      t.datetime "occurred_at"
    end

    create_table "subscriptions", force: true do |t|
      t.integer "user_id"
      t.integer "bottles_per_shipment"
      t.integer "bottles_left"
      t.string  "uuid"
    end

    create_table "bottle_events", force: true do |t|
      t.string   "bottle_uuid"
      t.string   "event_type"
      t.text     "data"
      t.datetime "created_at"
    end

    create_table "bottles", force: true do |t|
      t.integer "volume"
      t.decimal "cost_price"
      t.string  "uuid"
    end
  end
end

class Shipment < ActiveRecord::Base
end

class SubscriptionEvent < ActiveRecord::Base
  include EventSourcedRecord::Event

  serialize :data

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

  event_type :blank do
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

class BottleEvent < ActiveRecord::Base
  include EventSourcedRecord::Event

  serialize :data

  event_type :purchase do
    attributes :volume, :cost_price
  end
end

class Bottle < ActiveRecord::Base
  has_many :bottle_events

  validates :uuid, uniqueness: true
end

class BottleCalculator < EventSourcedRecord::Calculator
  events :bottle_events, :shipments

  def advance_purchase(event)
    @bottle.volume = event.volume
    @bottle.cost_price = event.cost_price
  end
end
