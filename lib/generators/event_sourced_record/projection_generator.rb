class EventSourcedRecord::ProjectionGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)
  argument :attributes, 
    :type => :array, :default => []

  def create_migration_file
    generate(
      "migration", "create_#{projection_table_name} #{migration_attributes}"
    )
  end

  def create_model_file
    template(
      'projection_model.rb', 
      File.join('app/models', class_path, "#{projection_file_name}.rb")
    )
  end

  hook_for :test_framework, as: :model

  private

  def migration_attributes
    attr_strings = attributes.map { |attr|
      attr_string = attr.name
      attr_string << ":#{attr.type}" if attr.type
      attr_string << ':index' if attr.has_index?
      attr_string
    }
    attr_strings << "uuid:string:uniq"
    attr_strings.join(' ')
  end


  def projection_class_name
    class_name
  end

  def projection_file_name
    file_name
  end

  def projection_parent_class_name
    "ActiveRecord::Base"
  end

  def projection_table_name
    table_name
  end
end
