require 'active_model'

class EventSourcedRecord::Event::EventTypeConfig
  include ::ActiveModel::Validations::ClassMethods

  attr_reader :_validators

  def initialize
    @_validators = Hash.new { |h,k| h[k] = [] }
    @attributes = []
  end

  def attributes(*attrs)
    attrs.present? ? @attributes = attrs : @attributes
  end

  def const_get(sym_or_str, inherit=true)
    ActiveModel::Validations.const_get(sym_or_str, inherit)
  end

  # Don't do anything; the interesting work has already been done in
  # `validate_with` adding validators to @_validators
  def validate(*args, &block)
  end

  def validate_record(record)
    _validators.values.flatten.each do |validator|
      validator.validate(record)
    end
  end
end
