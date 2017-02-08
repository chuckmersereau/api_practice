RSpec.shared_examples 'sorting examples' do |options|
  let(:sorting_param_or_created_at) { defined?(sorting_param) ? sorting_param : :created_at }

  before do
    resource.update_column(sorting_param_or_created_at, 2.days.ago)
  end

  it 'sorts resources if sorting_param is in list of permitted sorts' do
    api_login(user)
    get options[:action], parent_param_if_needed.merge(sort: "-#{sorting_param_or_created_at}")

    expect do
      get options[:action], parent_param_if_needed.merge(sort: sorting_param_or_created_at.to_s)
    end.to change { JSON.parse(response.body)['data'].first['id'] }

    expect(JSON.parse(response.body)['meta']['sort']).to eq(sorting_param_or_created_at.to_s)
  end

  it 'raises a 400 if sort param is not in list of permitted sorts' do
    api_login(user)
    get options[:action], parent_param_if_needed.merge(sort: 'id')
    expect(response.status).to eq(400)
    expect(JSON.parse(response.body)['errors'].first['detail']).to eq("Sorting by 'id' is not supported for this endpoint.")
  end

  it 'raises a 400 if sort param includes several sorting parameters' do
    api_login(user)
    get options[:action], parent_param_if_needed.merge(sort: 'id, uuid')
    expect(response.status).to eq(400)
    expect(JSON.parse(response.body)['errors'].first['detail']).to eq('The current API does not support multiple sorting parameters.')
  end
end
