RSpec.shared_examples 'sorting examples' do |options|
  let(:sorting_param_or_created_at) { defined?(sorting_param) ? sorting_param : :created_at }

  before { resource.update_column(sorting_param_or_created_at, 2.days.ago) }

  it 'sorts resources if sorting_param is in list of permitted sorts' do
    api_login(user)
    get options[:action], parent_param_if_needed.merge(sort: "#{sorting_param_or_created_at} DESC")

    expect do
      get options[:action], parent_param_if_needed.merge(sort: "#{sorting_param_or_created_at} ASC")
    end.to change { JSON.parse(response.body)['data'].first['id'] }

    expect(JSON.parse(response.body)['meta']['sort']).to eq("#{sorting_param_or_created_at} ASC")
  end

  it 'does not sort resources if sorting_param is not in list of permitted sorts' do
    api_login(user)
    get options[:action], parent_param_if_needed.merge(sort: 'id DESC')
    expect do
      get options[:action], parent_param_if_needed.merge(sort: 'id ASC')
    end.not_to change { JSON.parse(response.body)['data'].first['id'] }
    expect(JSON.parse(response.body)['meta']['sort']).to be_nil
  end
end
