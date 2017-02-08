module JsonApiHelper
  def json_response
    @json_response ||= parse_response_body
  end

  def check_collection_resource(total_items, additional_keys = [])
    expect(json_response.keys).to eq %w(data links meta)
    expect(resource_data.count).to eq total_items
    expect(first_or_only_item.keys).to eq item_keys(additional_keys)
    expect(first_or_only_item['type']).to eq resource_type.to_s
    expect(resource_object.keys).to match_array(resource_attributes) if defined?(resource_attributes)
  end

  def check_resource(additional_keys = [])
    expect(json_response.keys).to eq %w(data)
    expect(first_or_only_item.keys).to eq item_keys(additional_keys)
    expect(first_or_only_item['type']).to eq resource_type.to_s
    check_resource_attributes
    check_resource_relationships
  end

  def check_resource_attributes
    return unless defined?(resource_attributes)
    expect(resource_object.keys).to match_array(resource_attributes)
  end

  def check_resource_relationships
    return unless defined?(resource_associations)

    expect(first_or_only_item['relationships'].keys).to match_array(resource_associations)
  end

  def item_keys(additional_keys)
    (resource_object.empty? ? %w(id type) : %w(id type attributes)) + additional_keys
  end

  def invalid_status_detail
    body = json_response.is_a?(String) ? '' : JSON.pretty_generate(json_response)

    "\n\nResponse Status: #{returned_status}\nResponse Body: #{body}"
  end

  def first_or_only_item
    resource_data.is_a?(Array) ? resource_data.first : resource_data
  end

  def resource_object
    first_or_only_item.fetch('attributes', {})
  end

  def resource_data
    json_response['data']
  end

  def build_data(params, account_list_id: nil, relationships: {})
    params = {
      type: (defined?(request_type) ? request_type : resource_type),
      attributes: params.except('id')
    }

    if account_list_id
      params.merge!(
        relationships: {
          account_list: {
            data: {
              type: 'account_lists',
              id: account_list_id
            }
          }
        }
      )
    elsif relationships.present?
      params.merge(relationships: relationships)
    else
      params
    end
  end

  def returned_status
    if defined?(response_status)
      response_status
    else
      response.status
    end
  end

  private

  def parse_response_body
    if defined?(response_body)
      return '' if response_body.blank?

      JSON.parse(response_body)
    else
      return '' if response.body.blank?

      JSON.parse(response.body)
    end
  end
end
