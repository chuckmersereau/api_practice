RSpec.shared_examples 'update_examples' do |options = {}|
  options[:except] ||= []

  include_context 'common_variables'

  describe '#update' do
    unless options[:except].include?(:includes)
      include_examples 'including related resources examples', action: :update
    end

    unless options[:except].include?(:sparse_fieldsets)
      include_examples 'sparse fieldsets examples', action: :update
    end

    it 'updates resource for users that are signed in' do
      api_login(user)
      put :update, full_update_attributes

      expect(response.status).to eq(200), invalid_status_detail
      expect(resource.reload.send(update_reference_key)).to eq(update_reference_value)
    end

    it 'does not update the resource with unpermitted relationships' do
      if defined?(unpermitted_relationships)
        api_login(user)
        put :update, full_unpermitted_attributes

        expect(response.status).to eq(403), invalid_status_detail
        expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
      end
    end

    it 'does not update the resource when there are errors in sent data' do
      if can_run_incorrect_update_specs && incorrect_attributes
        api_login(user)
        put :update, full_incorrect_attributes

        expect(response.status).to eq(400), invalid_status_detail
        expect(response.body).to include('errors')
        expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
        expect(response_errors).to be_present

        if response_error_pointers.present?
          expect(
            incorrect_attributes.keys.any? do |incorrect_attribute|
              pointer_reference = "/data/attributes/#{incorrect_attribute}"

              response_error_pointers.include?(pointer_reference)
            end
          ).to be true
        end
      end
    end

    it 'does not update resources with outdated updated_at field' do
      api_login(user)
      full_update_attributes[:data][:attributes][:updated_in_db_at] = 1.year.ago
      full_update_attributes[:data][:attributes][:overwrite] = nil
      put :update, full_update_attributes

      expect(response.status).to eq(409), invalid_status_detail
      expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
      expect(response_errors).to be_present
    end

    it 'does not update resource for users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        put :update, full_update_attributes

        expect(response.status).to eq(403), invalid_status_detail
        expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
        expect(response_errors).to be_present
      end
    end

    it 'does not allow account_list to be set if account_list_id is in url' do
      if resource.respond_to?(:account_list_id) && parent_param_if_needed[:account_list_id].present?
        api_login(user)
        expect do
          put :update, account_list_id: account_list.uuid,
                       id: resource.uuid,
                       data: { type: resource_type,
                               id: resource.uuid,
                               relationships: {
                                 account_list: {
                                   data: {
                                     type: 'account_lists',
                                     id: create(:account_list).uuid
                                   }
                                 }
                               },
                               attributes: {
                                 overwrite: true
                               }
                             }
        end.not_to change { resource.reload.account_list_id }
        expect(response.status).to eq(200)
      end
    end

    it 'does not updates resource for users that are not signed in' do
      put :update, full_update_attributes

      expect(response.status).to eq(401), invalid_status_detail
      expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
      expect(response_errors).to be_present
    end

    it 'does not update a resource if the resource_type is incorrect' do
      api_login(user)
      put :update, attributes_with_incorrect_resource_type

      expect(response.status).to eq(409), invalid_status_detail
      expect(response_errors).to be_present
    end
  end

  def can_run_incorrect_update_specs
    !(defined?(dont_run_incorrect_update) && dont_run_incorrect_update)
  end
end
