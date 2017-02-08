RSpec.shared_examples 'index_examples' do |options = {}|
  options[:except] ||= []

  include_context 'common_variables'

  let(:active_record_association) { ActiveRecord::Relation }

  describe '#index' do
    unless options[:except].include?(:includes)
      include_examples 'including related resources examples', action: :index
    end

    unless options[:except].include?(:sparse_fieldsets)
      include_examples 'sparse fieldsets examples', action: :index
    end

    unless options[:except].include?(:sorting)
      include_examples 'sorting examples', action: :index
    end

    it 'shows resources to users that are signed in' do
      api_login(user)
      get :index, parent_param_if_needed
      expect(response.status).to eq(200), invalid_status_detail
      expect(response.body).to include(resource.class.first.send(reference_key).to_s) if reference_key
    end

    it 'does not show resources that do not belong to the signed in user' do
      api_login(user)
      expect { create(factory_type) }.not_to change {
        get :index, parent_param_if_needed
        JSON.parse(response.body)['data'].count
      }
    end

    it 'does not shows resources to users that are not signed in' do
      get :index, parent_param_if_needed
      expect(response.status).to eq(401), invalid_status_detail
    end

    it 'does not show resources to signed in users if they do not own the parent' do
      if defined?(parent_param)
        api_login(create(:user))
        get :index, parent_param
        expect(response.status).to eq(403), invalid_status_detail
      end
    end

    it 'paginates differently when specified in params' do
      api_login(user)

      get :index, parent_param_if_needed.merge(per_page: 1, page: 2)
      expect(response.status).to eq(200), invalid_status_detail
      expect(JSON.parse(response.body)['data'].length).to eq(1)
      expect(JSON.parse(response.body)['data'].first['id']).to_not eq(resource.id)
      expect(JSON.parse(response.body)['meta']['pagination']['per_page']).to eq('1')
      expect(JSON.parse(response.body)['meta']['pagination']['page']).to eq('2')
      expect(JSON.parse(response.body)['meta']['pagination']['total_count']).not_to be_nil
      expect(JSON.parse(response.body)['meta']['pagination']['total_pages']).not_to be_nil
    end
  end
end
