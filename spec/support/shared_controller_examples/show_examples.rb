RSpec.shared_examples 'show_examples' do |options = {}|
  options[:except] ||= []

  include_context 'common_variables'

  describe '#show' do
    unless options[:except].include?(:includes)
      include_examples 'including related resources examples', action: :show
    end

    unless options[:except].include?(:sparse_fieldsets)
      include_examples 'sparse fieldsets examples', action: :show
    end

    it 'shows resource to users that are signed in' do
      api_login(user)
      get :show, full_params
      expect(response.status).to eq(200)

      expect(response.body)
        .to include(resource.send(reference_key).to_json) if reference_key
    end

    it 'does not show resource to users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        get :show, full_params
        expect(response.status).to eq(403)
      end
    end

    it 'does not show resource to users that are not signed in' do
      get :show, full_params
      expect(response.status).to eq(401)
    end
  end
end
