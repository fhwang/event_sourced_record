require 'rails/generators/test_unit'

module TestUnit # :nodoc:
  module Generators # :nodoc:
    class ServiceGenerator < Base # :nodoc:
      source_root File.expand_path('../templates', __FILE__)
      check_class_collision suffix: "ServiceTest"

      def create_service_files
        template 'service_test.rb', File.join('test/services', class_path, "#{file_name}_test.rb")
      end
    end
  end
end

