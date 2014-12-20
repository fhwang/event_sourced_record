class EventSourcedRecord::EventGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)
  argument :attributes, 
    :type => :array, :default => []

  def create_migration_file
    attributes_str = attributes.map { |attr|
      attr_banner = attr.name
      attr_banner << ":#{attr.type}" if attr.type
      attr_banner << ':index' if attr.has_index?
      attr_banner
    }.join(' ')
    generate(
      "migration", "create_#{event_table_name} #{attributes_str}"
    )
  end

  def create_model_file
    template(
      'event_model.rb', 
      File.join('app/models', class_path, "#{event_file_name}.rb")
    )
  end

  hook_for :test_framework, as: :model

  private

  def event_class_name
    class_name
  end

  def event_file_name
    file_name
  end

  def event_table_name
    table_name
  end
end
