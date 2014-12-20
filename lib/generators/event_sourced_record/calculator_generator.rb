class EventSourcedRecord::CalculatorGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)
  argument :attributes, 
    :type => :array, :default => []

  def create_calculator_file
    template(
      'calculator.rb', File.join('app/services', class_path, "#{file_name}.rb")
    )
  end

  hook_for :test_framework, as: :service
  
  private

  def event_name
    file_name.gsub(/_calculator$/, '') + '_event'
  end
end
