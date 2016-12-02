module JsonApiHelper
  def json_response
    @json_response ||= JSON.parse(response_body)
  end

  def check_collection_resource(total_items, additional_keys = [])
    expect(json_response.keys).to eq %w(data links meta)
    expect(resource_data.count).to eq total_items
    expect(first_or_only_item.keys).to eq item_keys(additional_keys)
    expect(first_or_only_item['type']).to eq resource_type
  end

  def check_resource(additional_keys = [])
    expect(json_response.keys).to eq %w(data)
    expect(first_or_only_item.keys).to eq item_keys(additional_keys)
    expect(first_or_only_item['type']).to eq resource_type
    check_resource_attributes
    check_resource_relationships
  end

  def check_resource_attributes
    return unless defined?(resource_attributes)
    expect(resource_object.keys.sort).to eq(resource_attributes)
  end

  def check_resource_relationships
    return unless defined?(resource_associations)
    expect(first_or_only_item['relationships'].keys.sort).to eq(resource_associations)
  end

  def item_keys(additional_keys)
    %w(id type attributes) + additional_keys
  end

  def first_or_only_item
    resource_data.is_a?(Array) ? resource_data.first : resource_data
  end

  def resource_object
    first_or_only_item['attributes']
  end

  def resource_data
    json_response['data']
  end

  def build_data(params)
    { type: resource_type,
      attributes: params.except('id') }.merge(defined?(id) ? { id: id } : {})
  end
end
