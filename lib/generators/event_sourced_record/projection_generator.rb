require 'generators/event_sourced_record'

class EventSourcedRecord::ProjectionGenerator < ActiveRecord::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  argument :attributes, 
    :type => :array, :default => []

  def create_migration_file
    ar_major_version = ActiveRecord::VERSION::MAJOR
    if ar_major_version >= 4
      generate(
        "migration", "create_#{projection_table_name} #{migration_attributes}"
      )
    else
      migration_template(
        "projection_migration.ar3.rb", 
        "db/migrate/create_#{projection_table_name}.rb"
      )
    end
  end

  def create_model_file
    ar_major_version = ActiveRecord::VERSION::MAJOR
    template(
      "projection_model.ar#{ar_major_version}.rb", 
      File.join('app/models', class_path, "#{projection_file_name}.rb")
    )
  end

  def attributes_with_index
    attributes.select { |a| a.has_index? || (a.reference? && options[:indexes]) }
  end

  hook_for :test_framework, as: :model

  private

  def event_class_name
    projection_class_name + 'Event'
  end

  def has_many_foreign_key
    file_name + '_uuid'
  end

  def migration_attributes
    attr_strings = attributes.map { |attr|
      attr_string = attr.name
      attr_string << ":#{attr.type}" if attr.type
      attr_string << ':index' if attr.has_index?
      attr_string
    }
    attr_strings << "uuid:string:uniq"
    attr_strings << "created_at:datetime"
    attr_strings << "updated_at:datetime"
    attr_strings.join(' ')
  end

  def projection_migration_class_name
    "create_#{projection_table_name}".camelize
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
