class <%= projection_migration_class_name %> < ActiveRecord::Migration
  def change
    create_table :<%= projection_table_name %> do |t|
<% attributes.each do |attribute| -%>
      t.<%= attribute.type %> :<%= attribute.name %><%= attribute.inject_options %>
<% end -%>
      t.string :uuid
      t.timestamps
    end
<% attributes_with_index.each do |attribute| -%>
    add_index :<%= table_name %>, :<%= attribute.index_name %><%= attribute.inject_index_options %>
<% end -%>
    add_index :<%= table_name %>, :uuid, :unique => true
  end
end

