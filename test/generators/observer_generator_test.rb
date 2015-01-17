require 'test_helper'

class EventSourcedRecord::ObserverGeneratorTest < Rails::Generators::TestCase
  Destination = 'tmp/observer_generator_test'
  destination Destination
  setup :prepare_destination
  tests EventSourcedRecord::ObserverGenerator

  setup do
    config_path = File.join(Destination, 'config')
    FileUtils.mkdir(config_path)
    FileUtils.cp("test/generators/templates/application.rb", config_path)
    run_generator %w(subscription_event_observer)
  end

  test "creates a file for the observer" do
    assert_file("app/observers/subscription_event_observer.rb")
  end

  test "appends to the observer list in application.rb" do
    assert_file("config/application.rb") do |contents|
      assert_match(/config.active_record.observers \|\|= \[\]/, contents)
    end
  end
end
