namespace :<%= file_name %> do
  task :recalculate => :environment do
    <%= projection_class_name %>.all.each do |<%= file_name %>| 
      <%= calculator_class_name%>.new(<%= file_name %>).run.save!
    end
  end
end

