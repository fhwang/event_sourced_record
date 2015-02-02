<% module_namespacing do -%>
class <%= event_class_name %> < ActiveRecord::Base
  include EventSourcedRecord::Event

  serialize :data

  belongs_to :<%= belongs_to_name %>,
    foreign_key: '<%= belongs_to_foreign_key %>', primary_key: 'uuid'

  event_type :creation do
    # attributes :user_id
    #
    # validates :user_id, presence: true
  end
end
<% end -%>


