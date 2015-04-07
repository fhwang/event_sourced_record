# Getting started with Event Sourced Record

This document is intended to teach you how to use Event Sourced Record, and explains some of the concepts behind event sourcing in general.  It assumes you're already familiar with Rails.

Say you're starting a company that sells a shampoo subscription through the mail, and you want to use Event Sourcing to handle your subscription model.

## Requirements

Event Sourced Record supports Rails 3.2 and higher.

## Installation

Add this line to your application's Gemfile:

    gem 'event_sourced_record'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install event_sourced_record
    
Event Sourced Record uses observers, so you'll need to add them to your Gemfile:

    gem 'rails-observers'
    
## Generate your classes

You can use `rails generate event_sourced_record` to get started:

    $ rails generate event_sourced_record Subscription \
            user_id:integer bottles_per_shipment:integer \
            bottles_left:integer
            
This generates two migrations, which you might as well run now:

    $ rake db:migrate
    
This takes the same attribute list as `rails generate model`, but generates a number of different types of files.  Let's look at them in turn:

### Subscription

This is the model that you'd create in a typical Rails application, but here you'll find that we don't do much with it directly.

```ruby    
class Subscription < ActiveRecord::Base
  has_many :events, 
    class_name: 'SubscriptionEvent', 
    foreign_key: 'subscription_uuid', 
    primary_key: 'uuid'

  validates :uuid, uniqueness: true
end
```
`Subscription` holds data in a convenient form, but it's not responsible for changing its own state.  That's the responsiblity of the calculator, using the associated events.

In Event Sourcing parlance, `Subscription` is a "projection", meaning that everything in it can be derived from data and logic that lives elsewhere.

### SubscriptionEvent

You might never end up showing this model to end-users, but in fact it's the authoritative data in this system.  With all the events, you can rebuild the projections, but not the other way around.

`SubscriptionEvent` represents a timestamped event associated with a particular `Subscription`.  Each event should be treated as read-only; it's meant to be written once and then never modified.

```ruby
class SubscriptionEvent < ActiveRecord::Base
  include EventSourcedRecord::Event

  serialize :data

  belongs_to :subscription, 
    foreign_key: 'subscription_uuid', primary_key: 'uuid'

  event_type :creation do
    # attributes :user_id
    #
    # validates :user_id, presence: true
  end
end
```

### SubscriptionCalculator

This service class replays the event sequence to build a Subscription record that reflects current state.  You'll flesh it out by adding methods that advance the state of the Subscription for each individual type of event.

```ruby
class SubscriptionCalculator < EventSourcedRecord::Calculator
  events :subscription_events

  def advance_creation(event)

  end
end
```

### SubscriptionEventObserver

You can run `SubscriptionCalculator` yourself whenever you like, but `SubscriptionEventObserver` takes care of a core use-case. It monitors `SubscriptionEvent` (and other event classes, as we'll see) and tells `SubscriptionCalculator` to build or rebuild the `Subscription` every time there's a new event class saved.

```ruby
class SubscriptionEventObserver < ActiveRecord::Observer
  observe :subscription_event

  def after_create(event)
    SubscriptionCalculator.new(event).run.save!
  end
end
```

The generator registers this observer in `config/application.rb`:

    config.active_record.observers = :subscription_event_observer

### A Subscription rake file

The Rake file gives you a convenient command to rebuild every
`Subscription` whenever necessary.  Since you'll be building
`SubscriptionCalculator` to be idempotent, this will be a fairly safe operation.

```ruby
namespace :subscription do
  task :recalculate => :environment do
    Subscription.all.each do |subscription| 
      SubscriptionCalculator.new(subscription).run.save!
    end
  end
end
```
## Creation

The generated code starts you out with a `creation` event, but we'll want to define it to get some use out of it.

Above, we specified that subscriptions will have `user_id`, `bottles_per_shipment`, and `bottles_left`.  During the creation, we assume we can get `user_id` from `current_user` in the controller, and `bottles_per_shipment` is something that the user will specify during the initial signup.  Let's say, also, that sign up requires that you buy some bottles up-front, which we'll define on the initial event but not on `Subscription`.

### Define the creation event type

Fill out the `event_type` block in `SubscriptionEvent`:

```ruby
event_type :creation do
  attributes :bottles_per_shipment, :bottles_purchased, :user_id

  validates :bottles_per_shipment, presence: true, numericality: true
  validates :bottles_purchased, presence: true, numericality: true
  validates :user_id, presence: true
end
```    

> If you are using mass-assignment protection, which is on by default in Rails 3.2, you may want to make these attributes mass-assignable with `attr_accessible`.

This lets you build and save events with the attributes `bottles_per_shipment`,
`bottles_purchased`, and `user_id`, and validates those attributes -- as long as the event type is set by using the auto-generated scope:

```ruby
event = SubscriptionEvent.creation.new(
  bottles_purchased: 6,
  user_id: current_user.id
)
puts "Trying to purchase #{event.bottles_purchased} bottles"
event.valid?                         # false
event.errors[:bottles_per_shipment]  # ["can't be blank", "is not a number"]    
```

### Handle the creation in the calculator

Fill out the `advance_creation` method in `SubscriptionCalculator`:

```ruby
def advance_creation(event)
  @subscription.user_id = event.user_id
  @subscription.bottles_per_shipment = event.bottles_per_shipment
  @subscription.bottles_left = event.bottles_purchased
end
```
Note that for `user_id` and `bottles_per_shipment` we simply copy the field from the event to the subscription, but in the case of `bottles_purchased`, that is translated to `Subscription#bottles_left`.  This field will go up and down over time.

### Create a subscription, indirectly

Creating a subscription is a matter of creating the event itself:

```ruby
event = SubscriptionEvent.creation.new(
  bottles_per_shipment: 1,
  bottles_purchased: 6,
  user_id: current_user.id
)
event.save!
subscription = Subscription.last
puts "Created subscription #{subscription.id}"
```    
### What's happening here?

There's a lot going on here.  If you're curious, here's what's happening under the hood:

1. `SubscriptionEvent` saves, provided its event type validations are satisfied.
1. `SubscriptionObserver` is notified that a `SubscriptionEvent` was saved, so it runs the calculator.
1. `SubscriptionCalculator` collects all associated events around the `Subscription`, orders them by `created_at`, and runs them in order.
1. In the case of creation, we don't actually have a `Subscription` at the time we run the calculator for the first time.  So `SubscriptionCalculator` makes use of an auto-generated `subscription_uuid` attribute to tell subscriptions apart even when some of them have yet to be created in the database.
1. For each event, `SubscriptionCalculator` calls `advance_[event_type]`, which is responsible for updating the attributes on `@subscription` accordingly.
1. `SubscriptionObserver` takes the record returned by `SubscriptionCalculator` and saves it to the database.

This is a lot of indirection, which you don't have to understand right away.  When you hit more complex situations later, you'll find this indirection will come in handy.

## Change the settings for a subscription

Occasionally, subscribers will want to change their settings.  Let's say in this case we'll only allow them to change `bottles_per_shipment`.  So we add a new event type in `SubscriptionEvent`:

```ruby
event_type :change_settings do
  attributes :bottles_per_shipment

  validates :bottles_per_shipment, numericality: true
end
```    
And we add a method to handle this new event type to `SubscriptionCalculator`:

```ruby
def advance_change_settings(event)
  @subscription.bottles_per_shipment = event.bottles_per_shipment
end
```
If we want to change the subscription from the last example from 1 bottle per shipment to 2 bottles per shipment, this looks like this:

```ruby
subscription.bottles_per_shipment # 1
subscription.events.change_settings.create!(
  subscription_uuid: subscription.uuid, bottles_per_shipment: 2
)
subscription.reload
subscription.bottles_per_shipment # 2
```    
## Shipment

We created `SubscriptionEvent` to store events about `Subscription`, but you may find you have other kinds of classes that are like events in that they are time-based and relatively immutable.  Let's say that shipments of shampoo function this way in our system: As soon as they are inserted in the database they are applied against the associated subscription.

So let's create a `Shipment` class, using the standard Rails generator:

    rails generate model Shipment subscription_id:integer num_bottles:integer
    
And let's say that everytime a `Shipment` goes out the door, we deduct `Shipment#num_bottles` from `bottles_left` on the associated `Subscription`.  To do that we'll need to change the calculator, and the observer.

In `subscription_calculator.rb` we make two changes.  First, we add `:shipments` to `events`, which tells the calculator to include `Shipment` as an event that needs to be considered.  Then we add an `advance_shipment` method to handle each associated `Shipment`.

```ruby
class SubscriptionCalculator < EventSourcedRecord::Calculator
  events :subscription_events, :shipments
      
  # Other methods omitted

  def advance_shipment(shipment)
    @subscription.bottles_left -= shipment.num_bottles
  end
end
```  
In `subscription_event_observer.rb`, we add `:shipment` to `observer`, so the observer will know to fire when we create a shipment.

```ruby
class SubscriptionEventObserver < ActiveRecord::Observer
  observe :subscription_event, :shipment

  def after_create(event)
    SubscriptionCalculator.new(event).run.save!
  end
end
```

Note that `SubscriptionEventObserver#after_create` didn't change.  When a `Shipment` is created, `after_create` will treat that `Shipment` like another type of event.

## About calculators
    
To get the most benefit out of the calculator, you should make its work idempotent: That is, you should be to run it twice and have no side effects.  And don't forget that every time you call `SubscriptionCalculator#run`, it runs through all events in order, even events that have been considered before.  So things like sending emails, charging a credit card for a recurring order, or firing off analytic events should not happen anywhere inside `SubscriptionCalculator`.

The best way to think of it is that `Subscription` is a cache, and `SubscriptionCalculator` contains the logic that fills that cache.  Just as you wouldn't want to send an email every time you saved data in Redis, you wouldn't want to send an email every time you called `SubscriptionCalculator#run`.

For this reason, you'll find that event sourcing fits nicely with architectural styles that move these sorts of side effects out of the model, such as [service classes](https://blog.engineyard.com/2014/keeping-your-rails-controllers-dry-with-services) or [Data Context Interaction](http://dci-in-ruby.info/).

## Extending Subscription in production

Over time, your application will change, and `Subscription` will change accordingly.  It will handle new concepts which you will need to add to both pre-existing and future subscriptions.

Because `Subscription` is just a cache, event sourcing gives us a consistent way to handle both pre-existing and future records:

1. Write a migration if needed to add or change fields on the `subscriptions` table.
1. Modify `SubscriptionCalculator` to take the new fields into account.
1. Test, merge, and deploy to production.
1. Rebuild every `Subscription` by running `rake
   subscription:recalculate`.
    
Because you have designed `SubscriptionCalculator` to be idempotent, it is safe to re-run at any time you want -- for example, if you want to fill in a database column that didn't exist before.

## Debugging Subscription in production

The same process can work for fixing many bugs in production. Events themselves are usually a simple act of recording the user's intention.  Errors usually emerge in the calculator, which is responsible for the tougher work of interpreting a sequence of events.

So when you find a bug, you can often fix it via this process:

1. Write a test to reproduce the bug.
1. Fix `SubscriptionCalculator` to fix the bug.
1. Merge and deploy to production.
1. Rebuild every `Subscription` by running `rake
   subscription:recalculate`.

Remember, `SubscriptionCalculator` is idempotent, so this process will fix all the records affected by the bug will leaving the others unchanged.  It will also spare you the agonizing effort of picking through data in `rails console` to guess which records are broken. Why go to the trouble?  Just re-run the whole thing and move on.

## Reporting

Because `SubscriptionCalculator` rebuilds a record in sequence, it's a piece of cake to only partially rebuild up to a certain time, which can save a lot of time in generating retrospective reports:
```ruby
calculator = SubscriptionCalculator.new(subscription)
sub_at_end_of_year = calculator.run(last_event_time: Date.new(2014,12,31))
```
Note that the returned instance is un-saved, and shouldn't be saved to `subscriptions`, but it's now a piece of cake to take those values and send them to whatever reporting system you have in place.

