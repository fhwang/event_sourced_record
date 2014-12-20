class <%= class_name %> < ActiveRecord::Observer
  observe :<%= event_name %>

  def after_create(event)
    <%= calculator_class_name %>.new(event).run.save!
  end
end

