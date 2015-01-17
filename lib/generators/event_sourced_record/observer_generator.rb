class EventSourcedRecord::ObserverGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  def create_observer_file
    template(
      'observer.rb', 
      File.join('app/observers', class_path, "#{file_name}.rb")
    )
  end

  def create_application_observer_hook
    application do
    "config.active_record.observers ||= []
    config.active_record.observers << :#{file_name}"
    end
  end

  private

  def calculator_class_name
    (projection_name + '_calculator').camelize
  end

  def event_name
    projection_name + '_event'
  end

  def event_uuid_field
    projection_name + '_uuid'
  end

  def projection_name
    file_name.gsub(/_event_observer$/, '')
  end
end
