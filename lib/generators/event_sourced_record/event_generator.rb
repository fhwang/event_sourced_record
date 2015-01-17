require 'generators/event_sourced_record'

class EventSourcedRecord::EventGenerator < ActiveRecord::Generators::Base
  source_root File.expand_path('../templates', __FILE__)
  argument :attributes, 
    :type => :array, :default => []

  def create_migration_file
    ar_major_version = ActiveRecord::VERSION::MAJOR
    if ar_major_version >= 4
      attributes_str = attributes.map { |attr|
        attr_banner = attr.name
        attr_banner << ":#{attr.type}" if attr.type
        attr_banner << ':index' if attr.has_index?
        attr_banner
      }.join(' ')
      generate(
        "migration", "create_#{event_table_name} #{attributes_str}"
      )
    else
      migration_template(
        "event_migration.ar3.rb", "db/migrate/create_#{event_table_name}.rb"
      )
    end
  end

  def create_model_file
    template(
      'event_model.rb', 
      File.join('app/models', class_path, "#{event_file_name}.rb")
    )
  end

  def attributes_with_index
    attributes.select { |a| a.has_index? || (a.reference? && options[:indexes]) }
  end

  hook_for :test_framework, as: :model

  private

  def belongs_to_foreign_key
    belongs_to_name +  '_uuid'
  end

  def belongs_to_name
    file_name.gsub(/_event/, '')
  end

  def event_migration_class_name
    "create_#{event_table_name}".camelize
  end

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
