<% module_namespacing do -%>
class <%= projection_class_name %> < <%= projection_parent_class_name.classify %>
<% attributes.select {|attr| attr.reference? }.each do |attribute| -%>
  belongs_to :<%= attribute.name %>
<% end -%>
  has_many :<%= file_name %>_events

  validates :uuid, uniqueness: true
end
<% end -%>

