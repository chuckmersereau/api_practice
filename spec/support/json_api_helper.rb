module JsonApiHelper
  def json_response
    @json_response ||= JSON.parse(relevate_response)
  end

  def relevate_response
    defined?(response_body) ? response_body : response.body
  end

  def check_collection_resource(total_items, additional_keys = [])
    expect(json_response.keys).to eq %w(data)
    expect(resource_data.count).to eq total_items
    expect(first_or_only_item.keys).to eq item_keys(additional_keys)
    expect(first_or_only_item['type']).to eq resource_type
  end

  def check_resource(additional_keys = [])
    expect(json_response.keys).to eq %w(data)
    expect(first_or_only_item.keys).to eq item_keys(additional_keys)
    expect(first_or_only_item['type']).to eq resource_type
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
