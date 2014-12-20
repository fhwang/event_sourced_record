require 'test_helper'

class EventSourcedRecord::CalculatorGeneratorTest < Rails::Generators::TestCase
  destination 'tmp/calculator_generator_test'
  setup :prepare_destination
  tests EventSourcedRecord::CalculatorGenerator

  setup do
    @generate_calls = Hash.new { |h,k| h[k] = [] }
    EventSourcedRecord::CalculatorGenerator.any_instance.stubs(:generate).with { |name, arg_string|
      @generate_calls[name] << arg_string
    }
    run_generator %w(subscription_calculator)
  end

  test "creates a calculator" do
    assert_file("app/services/subscription_calculator.rb") do |contents|
      assert_match(
        /class SubscriptionCalculator < EventSourcedRecord::Calculator/,
        contents
      )
      assert_match(/def advance_creation\(event\)/, contents)
    end
  end
end
