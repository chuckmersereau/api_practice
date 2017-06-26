RSpec.shared_examples 'sorting examples' do |options|
  let(:sorting_param) { described_class.new.send(:permitted_sorting_params).first || described_class::PERMITTED_SORTING_PARAM_DEFAULTS.second }

  let(:permit_multiple_sorting_params?) { described_class::PERMIT_MULTIPLE_SORTING_PARAMS }

  def sorting_param_nullable?
    !%w(created_at updated_at).include?(sorting_param)
  end

  before do
    resource.update_column(sorting_param, 1.day.ago) if sorting_param.ends_with?('_at')
    unless resource.class.where.not(sorting_param => resource.send(sorting_param)).exists?
      raise "To test sorting, there should be a resource with attribute #{sorting_param} NOT equal to #{resource.send(sorting_param)}"
    end
  end

  it 'sorts resources if sorting_param is in list of permitted sorts' do
    api_login(user)
    get options[:action], parent_param_if_needed.merge(sort: "-#{sorting_param}")

    expect do
      get options[:action], parent_param_if_needed.merge(sort: sorting_param.to_s)
    end.to change { JSON.parse(response.body)['data'].first['id'] }

    expect(JSON.parse(response.body)['meta']['sort']).to eq(sorting_param.to_s)
  end

  it 'raises a 400 if sort param is not in list of permitted sorts' do
    api_login(user)
    get options[:action], parent_param_if_needed.merge(sort: 'id')
    expect(response.status).to eq(400)
    expect(JSON.parse(response.body)['errors'].first['detail']).to eq('Sorting by id is not supported for this endpoint.')
  end

  context 'sorting nulls' do
    before do
      next unless sorting_param_nullable?

      resource.update_column(sorting_param, nil)
      raise "To test sorting by null values, there should be a resource with attribute #{sorting_param} as null" unless resource.class.where(sorting_param => nil).exists?
      raise "To test sorting by null values, there should be a resource with attribute #{sorting_param} as NOT null" unless resource.class.where.not(sorting_param => nil).exists?
    end

    it 'sorts resources based on null values first or last' do
      next unless sorting_param_nullable?

      api_login(user)
      get options[:action], parent_param_if_needed.merge(sort: "#{sorting_param} nulls")
      expect(JSON.parse(response.body)['meta']['sort']).to eq("#{sorting_param} nulls")

      expect do
        get options[:action], parent_param_if_needed.merge(sort: "#{sorting_param} -nulls")
      end.to change { JSON.parse(response.body)['data'].first['id'] }

      expect(JSON.parse(response.body)['meta']['sort']).to eq("#{sorting_param} -nulls")
    end

    it 'raises an error if the nulls argument is not formatted as expected' do
      next unless sorting_param_nullable?

      api_login(user)
      get options[:action], parent_param_if_needed.merge(sort: "#{sorting_param} nil")
      expect(response.status).to eq(400)
      expect(JSON.parse(response.body)['errors'].first['detail']).to eq('Bad format for sort param.')
    end
  end

  context 'sorting by only one parameter' do
    it 'raises a 400 if sort param includes several sorting parameters' do
      next if permit_multiple_sorting_params?

      api_login(user)
      get options[:action], parent_param_if_needed.merge(sort: 'id,uuid')
      expect(response.status).to eq(400)
      expect(JSON.parse(response.body)['errors'].first['detail']).to eq('This endpoint does not support multiple sorting parameters.')
    end
  end

  context 'sorting by multiple parameters' do
    it 'allows sorting by multiple sorting parameters' do
      next unless permit_multiple_sorting_params?

      api_login(user)
      get options[:action], parent_param_if_needed.merge(sort: '-created_at,updated_at')

      expect do
        get options[:action], parent_param_if_needed.merge(sort: 'created_at,-updated_at')
      end.to change { JSON.parse(response.body)['data'].first['id'] }

      expect(response.status).to eq(200)
    end

    it 'raises a 400 if one of the sorting params is not in list of permitted sorts' do
      next unless permit_multiple_sorting_params?

      api_login(user)
      get options[:action], parent_param_if_needed.merge(sort: 'created_at,id')
      expect(response.status).to eq(400)
      expect(JSON.parse(response.body)['errors'].first['detail']).to eq('Sorting by id is not supported for this endpoint.')
    end
  end
end
