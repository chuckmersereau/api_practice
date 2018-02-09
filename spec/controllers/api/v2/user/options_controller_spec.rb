require 'rails_helper'

RSpec.describe Api::V2::User::OptionsController, type: :controller do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:factory_type) { :user_option }
  let!(:resource) { create(:user_option, user: user, created_at: 10.minutes.ago) }
  let!(:second_resource) { create(:user_option, user: user) }
  let(:id) { resource.key }
  let(:correct_attributes) { attributes_for(:user_option) }
  let(:unpermitted_attributes) { nil }
  let(:incorrect_attributes) { nil }

  include_context 'common_variables'

  include_examples 'index_examples'

  options = { except: [] }

  describe '#show' do
    include_examples 'including related resources examples', action: :show unless options[:except].include?(:includes)

    include_examples 'sparse fieldsets examples', action: :show unless options[:except].include?(:sparse_fieldsets)

    it 'shows resource to users that are signed in' do
      api_login(user)
      get :show, full_params
      expect(response.status).to eq(200), invalid_status_detail

      expect(response.body)
        .to include(resource.send(reference_key).to_json) if reference_key
    end

    it 'does not show resource to users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        get :show, full_params
        expect(response.status).to eq(404), invalid_status_detail
      end
    end

    it 'does not show resource to users that are not signed in' do
      get :show, full_params
      expect(response.status).to eq(401), invalid_status_detail
    end
  end

  include_examples 'create_examples'

  describe '#update' do
    include_examples 'including related resources examples', action: :update unless options[:except].include?(:includes)

    include_examples 'sparse fieldsets examples', action: :update unless options[:except].include?(:sparse_fieldsets)

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
      full_update_attributes[:data][:attributes][:overwrite] = false
      full_update_attributes[:data][:attributes][:updated_in_db_at] = 1.year.ago
      put :update, full_update_attributes

      expect(response.status).to eq(409), invalid_status_detail
      expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
      expect(response_errors).to be_present
      expect(response_errors.first).to have_key('meta')
      expect(response_errors.first['meta']).to have_key('updated_in_db_at')
    end

    it 'does not update resource for users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        put :update, full_update_attributes

        expect(response.status).to eq(404), invalid_status_detail
        expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
        expect(response_errors).to be_present
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

  describe '#destroy' do
    it 'destroys resource object to users that are signed in' do
      api_login(user)

      expect do
        delete :destroy, full_params
      end.to change(&count_proc).by(-1)

      expect(response.status).to eq(204), invalid_status_detail
    end

    it 'does not destroy the resource for users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        expect do
          delete :destroy, full_params
        end.not_to change(&count_proc)
        expect(response.status).to eq(404), invalid_status_detail
      end
    end

    it 'does not destroy resource object to users that are signed in' do
      expect do
        delete :destroy, full_params
      end.not_to change(&count_proc)
      expect(response.status).to eq(401), invalid_status_detail
    end
  end
end
