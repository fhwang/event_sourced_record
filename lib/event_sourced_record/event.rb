require 'active_record/immutable'

module EventSourcedRecord::Event
  include ActiveRecord::Immutable

  def self.included(model)
    model.cattr_accessor :_event_type_configs
    model.extend ClassMethods
    model.after_initialize :ensure_data
    model.after_initialize :ensure_projection_uuid
    model.after_initialize :lock_event_type
    model.before_validation :ensure_occurred_at, on: :create
    model.validates :event_type, presence: true
    model.validate :validate_corrent_event_type
    model.validate :validate_by_event_type
  end

  def event_type
    attributes["event_type"]
  end

  def event_type=(value)
    if @event_type_locked
      raise EventTypeImmutableError, "Event types can't be changed"
    else
      write_attribute(:event_type, value)
    end
  end

  def respond_to?(meth, include_all = false)
    if event_type_config && event_type_config.attributes.include?(meth)
      true
    elsif event_type_config && event_type_config.attributes.any? { |a| "#{a}=" == meth }
      true
    else
      super
    end
  end

  private

  def ensure_data
    self.data ||= {}
  end

  def ensure_projection_uuid
    unless self.send(projection_uuid_name)
      self.send("#{projection_uuid_name}=", SecureRandom.uuid)
    end
  end

  def event_type_config
    self.class.event_type_config(event_type)
  end

  def lock_event_type
    @event_type_locked = true
  end

  def ensure_occurred_at
    self.occurred_at = Time.now unless occurred_at
  end

  def method_missing(meth, *args, &block)
    if event_type_config && event_type_config.attributes.include?(meth)
      ensure_data
      self.data[meth.to_s]
    elsif event_type_config && event_type_config.attributes.any? { |a| "#{a}=".to_sym == meth }
      ensure_data
      attr = meth.to_s.gsub(/=$/, '')
      self.data[attr] = args.first
    else
      super
    end
  end

  def projection_uuid_name
    self.class.name.underscore.gsub(/_event$/, '') + '_uuid'
  end

  def validate_corrent_event_type
    unless self.class.event_types.include?(event_type.to_s)
      errors.add(:event_type, "is not a valid event type")
    end
  end

  def validate_by_event_type
    event_type_config.validate_record(self) if event_type_config
  end

  module ClassMethods
    def event_type(event_type, &block)
      scope event_type, -> { where(event_type: event_type) }
      self._event_type_configs ||= HashWithIndifferentAccess.new
      config = EventTypeConfig.new
      self._event_type_configs[event_type] = config
      config.instance_eval(&block)
    end

    def event_type_config(event_type)
      self._event_type_configs[event_type]
    end

    def event_types
      self._event_type_configs.keys
    end
  end

  class EventTypeImmutableError < StandardError; end
end

require 'event_sourced_record/event/event_type_config'
