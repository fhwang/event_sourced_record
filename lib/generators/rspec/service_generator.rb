require 'generators/rspec'

module Rspec
  module Generators # :nodoc:
    class ServiceGenerator < Base # :nodoc:
      source_root File.expand_path('../templates', __FILE__)
      check_class_collision suffix: "ServiceTest"

      def create_service_files
        template 'service_spec.rb', File.join('spec/services', class_path, "#{file_name}_spec.rb")
      end
    end
  end
end

