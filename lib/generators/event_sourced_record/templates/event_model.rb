<% module_namespacing do -%>
class <%= event_class_name %> < ActiveRecord::Base
  include EventSourcedRecord::Event

  event_type :creation do
    # attributes :user_id
    #
    # validates :user_id, presence: true
  end
end
<% end -%>


