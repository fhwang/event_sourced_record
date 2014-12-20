class <%= class_name %> < EventSourcedRecord::Calculator
  events :<%= event_name.pluralize %>

  def advance_creation(event)

  end
end
