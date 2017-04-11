require 'indefinite_article'

class DocumentationHelper
  attr_reader :resource

  def initialize(resource:, filepath: nil)
    @resource = Array[resource].flatten
    @filepath = filepath
    @data     = {}
  end

  def additional_attributes
    @additional_attributes ||= {
      'attributes.created_at': {
        description: 'The timestamp of when this resource was created',
        type: 'ISO8601 timestamp'
      },
      'attributes.updated_at': {
        description: 'The timestamp of when this resource was last updated',
        type: 'ISO8601 timestamp'
      },
      'attributes.updated_in_db_at': {
        description: 'This is to be used as a reference for the last time the resource was updated in the remote database - specifically for when data is updated while the client is offline.',
        type: 'ISO8601 timestamp',
        required: true
      }
    }
  end

  def additional_update_parameter_attributes
    @additional_update_parameter_attributes ||= {
      'attributes.overwrite': {
        description: "Only used for updating a record where you want to ignore the server's `updated_in_db_at` value and _force overwrite_ the values for the record. Must be `true` to work.",
        type: 'boolean'
      }
    }
  end

  def data_for(type:, action:)
    data.dig(type, action) || parse_raw_data_for(type, action)
  end

  def description_for(action)
    raw_data.dig(:actions, action, :description) || title_for(action)
  end

  def document_parameters_for(action:, context:)
    data_for(type: :parameters, action: action).deep_dup.sort.each do |name, attributes|
      next if attributes.key?(:ignore)

      if action == :update && !name.to_s.include?('updated_in_db_at')
        attributes.delete(:required)
      end

      description = attributes.delete(:description)

      context.send(
        :parameter,
        name,
        description,
        attributes
      )
    end
  end

  def document_response_fields_for(action:, context:)
    data_for(type: :response_fields, action: action).deep_dup.sort.each do |name, attributes|
      next if attributes.key?(:ignore)

      description = attributes.delete(:description)

      context.send(
        :response_field,
        name,
        description,
        attributes
      )
    end
  end

  def document_scope
    dup = resource.dup

    if dup.count > 1
      scope_front = "#{dup.shift}_api"
      scope_back  = dup.map(&:to_s).join('_')

      "#{scope_front}_#{scope_back}".to_sym
    else
      "entities_#{dup.first}".to_sym
    end
  end

  def filename
    @filename ||= "#{resource.last}.yml"
  end

  def filepath
    @filepath ||= build_filepath
  end

  def insert_documentation_for(action:, context:)
    document_parameters_for(action: action, context: context)
    document_response_fields_for(action: action, context: context)
  end

  def raw_data
    @raw_data ||= YAML.load_file(filepath).deep_symbolize_keys
  end

  def title_for(action)
    raw_data.dig(:actions, action, :title) || generate_title_for(action)
  end

  private

  attr_reader :data

  def additional_attributes_for(type, action)
    case type
    when :parameters
      additional_parameter_attributes_for(action)
    when :response_fields
      additional_response_field_attributes_for(action)
    end
  end

  def additional_parameter_attributes_for(action)
    attributes = additional_attributes.deep_dup

    case action
    when :create
      attributes[:'attributes.updated_in_db_at'].delete(:required)
      attributes
    when :update
      attributes.merge(additional_update_parameter_attributes)
    else
      {}
    end
  end

  def additional_response_field_attributes_for(action)
    attributes = additional_attributes.deep_dup

    case action
    when :index
      {}
    when :delete
      {}
    when :bulk_delete
      {}
    else
      attributes
    end
  end

  def assign_parsed_data_to_data(type, action, parsed_data)
    data[type]         ||= {}
    data[type][action] ||= {}

    data[type][action] = parsed_data

    parsed_data
  end

  def build_filepath
    resource_scope = resource[0..-2] << filename
    dirs = %w(spec support documentation) + resource_scope.map(&:to_s)

    Rails.root.join(*dirs).to_s
  end

  def generate_title_for(action)
    plural_name   = resource.last.to_s.titleize
    singular_name = singular_name_from_plural(plural_name)

    case action
    when :index
      "List #{plural_name}"
    when :show
      "Retrieve #{singular_name}"
    when :create
      "Create #{singular_name}"
    when :update
      "Update #{singular_name}"
    when :delete
      "Delete #{singular_name}"
    when :bulk_create
      "Bulk create #{plural_name}"
    when :bulk_update
      "Bulk update #{plural_name}"
    when :bulk_delete
      "Bulk delete #{plural_name}"
    end
  end

  def parse_attributes(attributes)
    attributes.each_with_object({}) do |(name, attrs), hash|
      new_name = "attributes.#{name}"

      hash[new_name] = attrs
    end
  end

  def parse_filters(filters)
    return {} if filters.empty?

    filters.each_with_object({}) do |(name, attrs), hash|
      new_name = "filter.#{name}"

      hash[new_name] = attrs
    end
  end

  def parse_object(object)
    return {} if object.empty?

    { data: object }
  end

  def parse_sorts(sorts)
    return {} if sorts.empty?

    sorts.each_with_object({}) do |(name, attrs), hash|
      new_name = "sort.#{name}"

      hash[new_name] = attrs
    end
  end

  def parameters_data(action)
    data.dig(:parameters, action) || {}
  end

  def parse_raw_data_for(type, action)
    found_data            = raw_data.dig(type, action) || {}
    additional_attributes = additional_attributes_for(type, action)
    parsed_attributes     = parse_attributes(found_data.dig(:attributes) || {})
    parsed_object         = parse_object(found_data.dig(:data) || {})
    parsed_sorts          = parse_sorts(found_data.dig(:sorts) || {})
    parsed_filters        = parse_filters(found_data.dig(:filters) || {})
    parsed_relationships  = parse_relationships(found_data.dig(:relationships) || {})

    parsed_data = parsed_object.merge(additional_attributes)
                               .merge(parsed_attributes)
                               .merge(parsed_filters)
                               .merge(parsed_sorts)
                               .merge(parsed_relationships)
                               .deep_symbolize_keys

    assign_parsed_data_to_data(type, action, parsed_data)
  end

  def parse_relationships(relationships)
    relationships.each_with_object({}) do |(name, attrs), hash|
      new_name  = "relationships.#{name}.data"
      new_attrs = attrs.dig(:data) || {}

      if new_attrs.key?(:description)
        hash[new_name] = new_attrs
      elsif attrs.key?(:ignore)
        hash[new_name] = attrs
      else
        new_name = "#{new_name}.id"
        hash[new_name] = new_attrs.dig(:id)
      end
    end
  end

  def response_fields_data(action)
    (data.dig(:response_fields, action) || {}).tap do |fields_data|
      return unless fields_data.present?

      additional_response_field_data.each do |key, value|
        fields_data[key] = value unless fields_data.key?(key)
      end
    end
  end

  def singular_name_from_plural(plural_name)
    plural_name.singularize.with_indefinite_article
  end
end
