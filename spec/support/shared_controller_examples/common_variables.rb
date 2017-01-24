RSpec.shared_examples 'common_variables' do
  let(:id_param) { defined?(id) ? { id: id } : {} }

  let(:full_params)            { id_param.merge(defined?(parent_param) ? parent_param : {}) }
  let(:parent_param_if_needed) { defined?(parent_param) ? parent_param : {} }

  let(:full_correct_attributes) do
    {
      data: {
        type: resource_type,
        attributes: correct_attributes.merge(updated_in_db_at: resource.updated_at)
      }
    }.merge(full_params)
  end

  let(:full_unpermitted_attributes) do
    {
      data: {
        type: resource_type,
        attributes: unpermitted_attributes.merge(updated_in_db_at: resource.updated_at)
      }
    }.merge(full_params)
  end

  let(:full_incorrect_attributes) do
    {
      data: {
        type: resource_type,
        attributes: incorrect_attributes.merge(updated_in_db_at: resource.updated_at)
      }
    }.merge(full_params)
  end

  let(:reference_key)   { defined?(given_reference_key) ? given_reference_key : correct_attributes.keys.first }
  let(:reference_value) { defined?(given_reference_value) ? given_reference_value : correct_attributes.values.first }
  let(:count_proc)      { defined?(count) ? count : -> { resources_count } }

  let(:resource_not_destroyed_scope) { defined?(not_destroyed_scope) ? not_destroyed_scope : resource.class }
  let(:serializer) { ActiveModel::Serializer.serializer_for(resource).new(resource) }
  let(:resource_type) { serializer._type || resource.class.to_s.underscore.tr('/', '_').pluralize }

  let(:response_errors) { JSON.parse(response.body)['errors'] }

  let(:response_error_pointers) do
    response_errors.map do |error|
      error['source']['pointer'] if error['source']
    end
  end

  let(:full_update_attributes) do
    if defined?(update_attributes)
      {
        data: {
          type: resource_type,
          attributes: update_attributes
        }
      }.merge(full_params)
    else
      full_correct_attributes
    end
  end

  let(:update_reference_key) do
    if defined?(given_update_reference_key)
      given_update_reference_key
    else
      full_update_attributes[:data][:attributes].keys.first
    end
  end

  let(:update_reference_value) do
    if defined?(given_update_reference_value)
      given_update_reference_value
    else
      full_update_attributes[:data][:attributes].values.first
    end
  end

  let(:attributes_with_incorrect_resource_type) do
    full_correct_attributes.tap do |params|
      params[:data][:type] = :gummybear # should definitely fail
    end
  end

  def resources_count
    defined?(reference_scope) ? reference_scope.count : resource_not_destroyed_scope.count
  end
end
