RSpec.shared_examples 'filtering examples' do |options|
  it 'reduces the count of items returned when a filter is used' do
    if defined?(filter_params)
      api_login(user)
      get options[:action], parent_param_if_needed

      expect do
        get options[:action], parent_param_if_needed.merge(filter: filter_params)
      end.to change { JSON.parse(response.body)['data'].length }.by(-1)
    end
  end

  it 'returns meta for given filter' do
    if defined?(filterer_class)
      api_login(user)
      filterer_class.filter_params.collect(&:to_s).each do |filter|
        get :index, filter: { filter => '' }
        expect(response.status).to eq(200)
        expect(JSON.parse(response.body)['meta']['filter'][filter]).to eq('')
      end
    end
  end
end
