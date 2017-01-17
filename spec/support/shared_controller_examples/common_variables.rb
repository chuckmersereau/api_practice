RSpec.shared_examples 'common_variables' do
  let(:id_param)                     { defined?(id) ? { id: id } : {} }
  let(:full_params)                  { id_param.merge(defined?(parent_param) ? parent_param : {}) }
  let(:parent_param_if_needed)       { defined?(parent_param) ? parent_param : {} }
  let(:full_correct_attributes)      { { data: { attributes: correct_attributes.merge(updated_in_db_at: resource.updated_at) } }.merge(full_params) }
  let(:full_unpermitted_attributes)  { { data: { attributes: unpermitted_attributes.merge(updated_in_db_at: resource.updated_at) } }.merge(full_params) }
  let(:full_incorrect_attributes)    { { data: { attributes: incorrect_attributes.merge(updated_in_db_at: resource.updated_at) } }.merge(full_params) }
  let(:reference_key)                { defined?(given_reference_key) ? given_reference_key : correct_attributes.keys.first }
  let(:reference_value)              { defined?(given_reference_value) ? given_reference_value : correct_attributes.values.first }
  let(:count_proc)                   { defined?(count) ? count : -> { resources_count } }
  let(:resource_not_destroyed_scope) { defined?(not_destroyed_scope) ? not_destroyed_scope : resource.class }
  let(:serializer) { ActiveModel::Serializer.serializer_for(resource).new(resource) }

  let(:full_update_attributes) do
    if defined?(update_attributes)
      {
        data: {
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

  def resources_count
    defined?(reference_scope) ? reference_scope.count : resource_not_destroyed_scope.count
  end
end
