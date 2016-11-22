
RSpec.shared_examples 'common_variables' do
  let(:id_param) { defined?(id) ? { id: id } : {} }
  let(:full_params) { id_param.merge(defined?(parent_param) ? parent_param : {}) }
  let(:parent_param_if_needed) { defined?(parent_param) ? parent_param : {} }
  let(:full_correct_attributes) { { data: { attributes: correct_attributes } }.merge(full_params) }
  let(:full_unpermitted_attributes) { { data: { attributes: unpermitted_attributes } }.merge(full_params) }
  let(:full_incorrect_attributes) { { data: { attributes: incorrect_attributes } }.merge(full_params) }
  let(:reference_key) { correct_attributes.keys.first }
  let(:reference_value) { correct_attributes.values.first }
end

RSpec.shared_examples 'show_examples' do
  include_examples 'common_variables'

  describe '#show' do
    it 'shows resource object to users that are signed in' do
      api_login(user)
      get :show, full_params
      expect(response.status).to eq(200)
      expect(response.body).to include(resource.send(reference_key).to_s)
    end

    it 'does not show resource for users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        get :show, full_params
        expect(response.status).to eq(403)
      end
    end

    it 'does not shows resource object to users that are signed in' do
      get :show, full_params
      expect(response.status).to eq(401)
    end
  end
end

RSpec.shared_examples 'update_examples' do
  include_examples 'common_variables'

  describe '#update' do
    it 'updates resource for users that are signed in' do
      api_login(user)
      put :update, full_correct_attributes
      expect(response.status).to eq(200)
      expect(resource.reload.send(reference_key)).to eq(reference_value)
    end

    it 'does not update the resource with unpermitted params' do
      if unpermitted_attributes
        api_login(user)
        put :update, full_unpermitted_attributes
        expect(response.status).to eq(403)
        expect(resource.reload.send(reference_key)).to_not eq(reference_value)
      end
    end

    it 'does not update the resource when there are errors in sent data' do
      if incorrect_attributes
        api_login(user)
        put :update, full_incorrect_attributes
        expect(response.status).to eq(400)
        expect(response.body).to include('errors')
        expect(resource.reload.send(reference_key)).to_not eq(reference_value)
      end
    end

    it 'does not update resource for users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        put :update, full_correct_attributes
        expect(response.status).to eq(403)
        expect(resource.reload.send(reference_key)).to_not eq(reference_value)
      end
    end

    it 'does not updates resource for users that are not signed in' do
      put :update, full_correct_attributes
      expect(response.status).to eq(401)
      expect(resource.reload.send(reference_key)).to_not eq(reference_value)
    end
  end
end

RSpec.shared_examples 'create_examples' do
  include_examples 'common_variables'

  describe '#create' do
    it 'creates resource for users that are signed in' do
      api_login(user)
      expect do
        post :create, full_correct_attributes
      end.to change { resource.class.count }.by(1)
      expect(response.status).to eq(200)
    end

    it 'does not create the resource when there are unpermitted params' do
      if unpermitted_attributes
        api_login(user)
        expect do
          post :create, full_unpermitted_attributes
        end.not_to change { resource.class.count }
        expect(response.status).to eq(403)
      end
    end

    it 'does not create the resource when there are errors in sent data' do
      if incorrect_attributes
        api_login(user)
        expect do
          post :create, full_incorrect_attributes
        end.not_to change { resource.class.count }
        expect(response.status).to eq(400)
        expect(response.body).to include('errors')
      end
    end

    it 'does not create resource for users that are not signed in' do
      expect do
        post :create, full_correct_attributes
      end.not_to change { resource.class.count }
      expect(response.status).to eq(401)
    end
  end
end

RSpec.shared_examples 'destroy_examples' do
  include_examples 'common_variables'

  describe '#destroy' do
    it 'shows current_user object to users that are signed in' do
      api_login(user)
      expect do
        delete :destroy, full_params
      end.to change { resource.class.count }.by(-1)
      expect(response.status).to eq(200)
    end

    it 'does not destroy the resource for users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        expect do
          delete :destroy, full_params
        end.not_to change { resource.class.count }
        expect(response.status).to eq(403)
      end
    end

    it 'does not shows current_user object to users that are signed in' do
      expect do
        delete :destroy, full_params
      end.not_to change { resource.class.count }
      expect(response.status).to eq(401)
    end
  end
end

RSpec.shared_examples 'index_examples' do
  include_examples 'common_variables'

  describe '#index' do
    it 'shows current_user object to users that are signed in' do
      api_login(user)
      create(factory_type)
      get :index, parent_param_if_needed
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['data'].count).to eq(resource.class.count - 1)
      expect(response.body).to include(resource.class.first.send(reference_key).to_s)
    end

    it 'does not shows current_user object to users that are signed in' do
      get :index, parent_param_if_needed
      expect(response.status).to eq(401)
    end
  end
end
