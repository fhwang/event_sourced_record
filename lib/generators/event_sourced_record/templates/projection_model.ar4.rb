<% module_namespacing do -%>
class <%= projection_class_name %> < <%= projection_parent_class_name.classify %>
<% attributes.select(&:reference?).each do |attribute| -%>
  belongs_to :<%= attribute.name %><%= ', polymorphic: true' if attribute.polymorphic? %>
<% end -%>
  has_many :events,
      class_name: '<%= event_class_name %>',
      foreign_key: '<%= has_many_foreign_key %>',
      primary_key: 'uuid'
<% if attributes.any?(&:password_digest?) -%>
  has_secure_password
<% end -%>

  validates :uuid, uniqueness: true
end
<% end -%>


