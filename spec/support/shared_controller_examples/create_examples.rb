RSpec.shared_examples 'create_examples' do |options = {}|
  options[:except] ||= []
  include_context 'common_variables'

  describe '#create' do
    unless options[:except].include?(:includes)
      include_examples 'including related resources examples', action: :create
    end
    include_examples 'sparse fieldsets examples', action: :create

    it 'creates resource for users that are signed in' do
      api_login(user)

      expect do
        post :create, full_correct_attributes
      end.to change { resource.class.count }.by(options[:count] || 1)

      expect(response.status).to eq(201), invalid_status_detail
    end

    it 'creates a resource associated to the correct parent' do
      if parent_association_if_needed.present?
        api_login(user)
        post :create, full_correct_attributes
        created_resource = resource.class.find_by_uuid(JSON.parse(response.body)['data']['id'])
        expect(created_resource.send(parent_association_if_needed).uuid).to eq parent_param_if_needed.values.last
      end
    end

    it 'does not create the resource when there are unpermitted relationships' do
      if defined?(unpermitted_relationships)
        api_login(user)
        expect do
          post :create, full_unpermitted_attributes
        end.not_to change { resource.class.count }
        expect(response.status).to eq(403), invalid_status_detail
      end
    end

    it 'does not create the resource when there are errors in sent data' do
      if incorrect_attributes
        api_login(user)

        expect do
          post :create, full_incorrect_attributes
        end.not_to change { resource.class.count }
        expect(response.status).to eq(400), invalid_status_detail
        expect(response.body).to include('errors')
      end
    end

    it 'does not create resource for users that are not signed in' do
      expect do
        post :create, full_correct_attributes
      end.not_to change { resource.class.count }
      expect(response.status).to eq(401), invalid_status_detail
    end

    it 'does not create a resource if the resource_type is incorrect' do
      api_login(user)

      expect { post :create, attributes_with_incorrect_resource_type }
        .not_to change { resources_count }

      expect(response.status).to eq(409), invalid_status_detail
      expect(response_errors).to be_present
    end
  end
end
