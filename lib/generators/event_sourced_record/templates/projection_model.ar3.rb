<% module_namespacing do -%>
class <%= projection_class_name %> < <%= projection_parent_class_name.classify %>
<% attributes.select {|attr| attr.reference? }.each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>
  has_many :events,
    class_name: '<%= event_class_name %>',
    foreign_key: '<%= has_many_foreign_key %>',
    primary_key: 'uuid'

  validates :uuid, uniqueness: true
end
<% end -%>

