RSpec.shared_examples 'create_examples' do
  include_context 'common_variables'

  describe '#create' do
    include_examples 'including related resources examples', action: :create
    include_examples 'sparse fieldsets examples', action: :create

    it 'creates resource for users that are signed in' do
      api_login(user)
      expect do
        post :create, full_correct_attributes
      end.to change { resource.class.count }.by(1)
      expect(response.status).to eq(201)
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
