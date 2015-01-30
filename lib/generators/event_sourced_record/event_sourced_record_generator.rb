class EventSourcedRecord::EventSourcedRecordGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)
  argument :attributes, 
    :type => :array, :default => [], 
    :banner => "field[:type][:index] field[:type][:index]"

  check_class_collision

  def create_calculator_class
    generate "event_sourced_record:calculator", "#{file_name}_calculator"
  end

  def create_event
    arguments = [
      "#{file_name}_uuid:string:index", "event_type:string", 
      "data:text", "created_at:datetime", "occurred_at:datetime"
    ].join(' ')
    generate "event_sourced_record:event", "#{file_name}_event #{arguments}"
  end

  def create_observer
    generate "event_sourced_record:observer", "#{file_name}_event_observer"
  end

  def create_projection
    attr_strings = attributes.map { |attr|
      attr_string = attr.name
      attr_string << ":#{attr.type}" if attr.type
      attr_string << ':index' if attr.has_index?
      attr_string
    }
    projection_attributes = attr_strings.join(' ')
    generate "event_sourced_record:projection", "#{file_name} #{projection_attributes}"
  end

  def create_rake_file
    template(
      "event_sourced_record.rake", 
      File.join("lib/tasks", class_path, "#{file_name}.rake")
    )
  end

  protected

  def calculator_class_name
    class_name + 'Calculator'
  end

  def projection_class_name
    class_name
  end
end
