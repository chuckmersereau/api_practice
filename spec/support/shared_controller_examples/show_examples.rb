RSpec.shared_examples 'show_examples' do |options = {}|
  options[:except] ||= []

  include_context 'common_variables'

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
        expect(response.status).to eq(403), invalid_status_detail
      end
    end

    it 'does not show resource to users that are not signed in' do
      get :show, full_params
      expect(response.status).to eq(401), invalid_status_detail
    end
  end
end
