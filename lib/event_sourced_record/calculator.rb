class EventSourcedRecord::Calculator
  def self.events(*event_symbols)
    @event_symbols = event_symbols
  end

  def self.event_classes
    @event_symbols.map { |sym|
      Module.const_get(sym.to_s.singularize.camelize)
    }
  end

  def initialize(lookup)
    @lookup = lookup
  end

  def run(options = {})
    instance_variable_set(projection_variable_name, find_or_build_record)
    sorted_events(options[:last_event_time]).each do |event|
      advance_event(event)
    end
    instance_variable_get projection_variable_name
  end

  private

  def advance_event(event)
    if event.respond_to?(:event_type)
      method = "advance_#{event.event_type}"
    else
      method = "advance_#{event.class.name.underscore}"
    end
    self.send(method, event)
  end

  def event_class
    Module.const_get(projection_class_name + 'Event')
  end

  def find_or_build_record
    case @lookup
    when Integer
      projection_class.where(id: @lookup).first
    when projection_class
      projection_class.where(id: @lookup.id).first
    when *self.class.event_classes
      find_or_build_record_by_event_instance(@lookup)
    else
      find_or_build_record_by_uuid(@lookup)
    end
  end

  def find_or_build_record_by_event_instance(event)
    if event.respond_to?(uuid_field)
      find_or_build_record_by_uuid(event.send(uuid_field))
    else
      conditions = {id: event.send(projection_name + '_id')}
      projection_class.where(conditions).first
    end
  end

  def find_or_build_record_by_uuid(uuid)
    projection_class.where(uuid: uuid).first || projection_class.new(uuid: uuid)
  end

  def projection_class
    Module.const_get(projection_class_name)
  end

  def projection_class_name
    self.class.name.gsub(/Calculator$/, '')
  end

  def projection_name
    projection_class_name.underscore
  end

  def projection_variable_name
    "@#{projection_name}".to_sym
  end

  def sorted_events(last_event_time)
    projection = instance_variable_get projection_variable_name
    self.class.event_classes.map { |event_class|
      conditions = nil
      if event_class.column_names.include?(uuid_field)
        conditions = {uuid_field => projection.uuid}
      else
        conditions = {projection_name + '_id' => projection.id} if projection
      end
      conditions ? event_class.where(conditions).to_a : []
    }.flatten.sort_by{ |evt| occurrence_time(evt) }.reject { |evt|
      if last_event_time
        occurrence_time(evt) > last_event_time
      end
    }
  end

  def occurrence_time(event)
    if event.respond_to?(:occurred_at) && event.occurred_at
      event.occurred_at
    else
      event.created_at
    end
  end

  def uuid_field
    projection_name + '_uuid'
  end
end
