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
end
