require 'generators/rspec'

module Graip
  module Generators
    class ControllerGenerator < Rails::Generators::NamedBase
      source_root File.expand_path('../templates', __FILE__)

      def generate_controller
        return if name.blank?

        full_file_name = "#{file_name}_controller.rb"
        file_path = File.join('app/controllers', class_path, full_file_name)

        template 'controller.rb.erb', file_path
      end

      def generate_controller_spec
        full_file_name = "#{file_name}_controller_spec.rb"
        file_path = File.join('spec/controllers', class_path, full_file_name)

        template 'controller_spec.rb.erb', file_path
      end

      def generate_acceptance_spec
        full_file_name = "#{file_name}_spec.rb"
        file_path = File.join('spec/acceptance', class_path, full_file_name)

        template 'acceptance_spec.rb.erb', file_path
      end

      private

      def build_parent_namespacing
        return if class_path.empty?

        class_path.map(&:camelize).join('::').concat('::')
      end

      def dashed_resource_name
        @dashed_resource_name ||= resource_name.dasherize
      end

      def dashed_resources_name
        @dashed_resources_name ||= resources_name.dasherize
      end

      def parent_namespacing
        @parent_namespaces ||= build_parent_namespacing
      end

      def resource_class_name
        @resource_class_name ||= resource_name.camelize
      end

      def resource_instance
        @resource_instance ||= "@#{resource_name}"
      end

      def resource_name
        @resource_name ||= file_name.singularize
      end

      def resources_instance
        @resources_instance ||= "@#{resources_name}"
      end

      def resources_name
        @resources_name ||= file_name.pluralize
      end

      def resource_human_name
        @resource_human_name ||= resource_name.humanize(capitalize: false)
      end

      def resources_human_name
        @resources_human_name ||= resource_human_name.pluralize
      end
    end
  end
end
