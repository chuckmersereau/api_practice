
RSpec.shared_examples 'common_variables' do
  let(:id_param)                     { defined?(id) ? { id: id } : {} }
  let(:full_params)                  { id_param.merge(defined?(parent_param) ? parent_param : {}) }
  let(:parent_param_if_needed)       { defined?(parent_param) ? parent_param : {} }
  let(:full_correct_attributes)      { { data: { attributes: correct_attributes.merge(updated_in_db_at: resource.updated_at) } }.merge(full_params) }
  let(:full_unpermitted_attributes)  { { data: { attributes: unpermitted_attributes.merge(updated_in_db_at: resource.updated_at) } }.merge(full_params) }
  let(:full_incorrect_attributes)    { { data: { attributes: incorrect_attributes.merge(updated_in_db_at: resource.updated_at) } }.merge(full_params) }
  let(:reference_key)                { defined?(given_reference_key) ? given_reference_key : correct_attributes.keys.first }
  let(:resource_not_destroyed_scope) { defined?(not_destroyed_scope) ? not_destroyed_scope : resource.class }
  let(:serializer)                   { ActiveModel::Serializer.serializer_for(resource).new(resource) }
  let(:response_errors)              { JSON.parse(response.body)['errors'] }

  let(:response_error_pointers) do
    response_errors.map do |error|
      error['source']['pointer'] if error['source']
    end
  end

  let(:full_update_attributes) do
    if defined?(update_attributes)
      {
        data: {
          attributes: update_attributes
        }
      }.merge(full_params)
    else
      full_correct_attributes
    end
  end

  let(:update_reference_key) do
    if defined?(given_update_reference_key)
      given_update_reference_key
    else
      full_update_attributes[:data][:attributes].keys.first
    end
  end

  let(:update_reference_value) do
    if defined?(given_update_reference_value)
      given_update_reference_value
    else
      full_update_attributes[:data][:attributes].values.first
    end
  end

  def resources_count
    defined?(reference_scope) ? reference_scope.count : resource.class.count
  end
end

RSpec.shared_examples 'show_examples' do
  include_context 'common_variables'

  describe '#show' do
    include_examples 'including related resources examples', action: :show
    include_examples 'sparse fieldsets examples', action: :show

    it 'shows resource to users that are signed in with attributes and relationships properly displaying uuid' do
      api_login(user)
      get :show, full_params
      expect(response.status).to eq(200)
      expect(response.body).to include(resource.send(reference_key).to_json) if reference_key
      if (relationships = JSON.parse(response.body)['data']['relationships'])
        relationships.keys.each { |key| expect_uuids_in_relationships(relationships[key]['data']) }
      end
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

  def expect_uuids_in_relationships(relationship_data)
    if relationship_data.is_a?(Array)
      relationship_data.each { |related| expect(related['id'].length).to eq(36) }
    elsif relationship_data
      expect(relationship_data['id'].length).to eq(36)
    end
  end
end

RSpec.shared_examples 'update_examples' do
  include_context 'common_variables'

  describe '#update' do
    include_examples 'including related resources examples', action: :update
    include_examples 'sparse fieldsets examples', action: :update

    it 'updates resource for users that are signed in' do
      api_login(user)
      put :update, full_update_attributes

      expect(response.status).to eq(200)
      expect(resource.reload.send(update_reference_key)).to eq(update_reference_value)
    end

    it 'does not update the resource with unpermitted params' do
      if unpermitted_attributes
        api_login(user)
        put :update, full_unpermitted_attributes

        expect(response.status).to eq(403)
        expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
      end
    end

    it 'does not update the resource when there are errors in sent data' do
      if incorrect_attributes
        api_login(user)
        put :update, full_incorrect_attributes

        expect(response.status).to eq(400)
        expect(response.body).to include('errors')
        expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
        expect(response_errors).to be_present

        if response_error_pointers.present?
          expect(
            incorrect_attributes.keys.any? do |incorrect_attribute|
              pointer_reference = "/data/attributes/#{incorrect_attribute}"

              response_error_pointers.include?(pointer_reference)
            end
          ).to be true
        end
      end
    end

    it 'does not update resources with outdated updated_at field' do
      api_login(user)
      full_update_attributes[:data][:attributes][:updated_in_db_at] = 1.year.ago
      put :update, full_update_attributes

      expect(response.status).to eq(400)
      expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
      expect(response_errors).to be_present
    end

    it 'does not update resource for users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        put :update, full_update_attributes

        expect(response.status).to eq(403)
        expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
        expect(response_errors).to be_present
      end
    end

    it 'does not updates resource for users that are not signed in' do
      put :update, full_update_attributes

      expect(response.status).to eq(401)
      expect(resource.reload.send(update_reference_key)).to_not eq(update_reference_value)
      expect(response_errors).to be_present
    end
  end
end

RSpec.shared_examples 'create_examples' do
  include_context 'common_variables'

  describe '#create' do
    include_examples 'including related resources examples', action: :create
    include_examples 'sparse fieldsets examples', action: :create

    it 'creates resource for users that are signed in' do
      api_login(user)
      expect do
        post :create, full_correct_attributes
      end.to change { resources_count }.by(1)
      expect(response.status).to eq(201)
    end

    it 'does not create the resource when there are unpermitted params' do
      if unpermitted_attributes
        api_login(user)
        expect do
          post :create, full_unpermitted_attributes
        end.not_to change { resources_count }
        expect(response.status).to eq(403)
        expect(response_errors).to be_present
      end
    end

    it 'does not create the resource when there are errors in sent data' do
      if incorrect_attributes
        api_login(user)

        expect do
          post :create, full_incorrect_attributes
        end.not_to change { resources_count }

        expect(response.status).to eq(400)
        expect(response.body).to include('errors')
      end
    end

    it 'does not create resource for users that are not signed in' do
      expect do
        post :create, full_correct_attributes
      end.not_to change { resources_count }

      expect(response.status).to eq(401)
      expect(response_errors).to be_present
    end
  end
end

RSpec.shared_examples 'destroy_examples' do
  include_context 'common_variables'

  describe '#destroy' do
    it 'destroys resource object to users that are signed in' do
      api_login(user)
      expect do
        delete :destroy, full_params
      end.to change { resource_not_destroyed_scope.count }.by(-1)
      expect(response.status).to eq(204)
    end

    it 'does not destroy the resource for users that do not own the resource' do
      if defined?(id)
        api_login(create(:user))
        expect do
          delete :destroy, full_params
        end.not_to change { resource_not_destroyed_scope.count }
        expect(response.status).to eq(403)
      end
    end

    it 'does not destroy resource object to users that are signed in' do
      expect do
        delete :destroy, full_params
      end.not_to change { resource_not_destroyed_scope.count }
      expect(response.status).to eq(401)
    end
  end
end

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

    before do
      resource.update(created_at: 2.days.ago)
    end

    it 'shows resources to users that are signed in' do
      api_login(user)
      get :index, parent_param_if_needed
      expect(response.status).to eq(200)
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
      expect(response.status).to eq(401)
    end

    it 'does not show resources to signed in users if they do not own the parent' do
      if defined?(parent_param)
        api_login(create(:user))
        get :index, parent_param
        expect(response.status).to eq(403)
      end
    end

    it 'paginates differently when specified in params' do
      api_login(user)

      get :index, parent_param_if_needed.merge(per_page: 1, page: 2)
      expect(response.status).to eq(200)
      expect(JSON.parse(response.body)['data'].length).to eq(1)
      expect(JSON.parse(response.body)['data'].first['id']).to_not eq(resource.id)
      expect(JSON.parse(response.body)['meta']['pagination']['per_page']).to eq('1')
      expect(JSON.parse(response.body)['meta']['pagination']['page']).to eq('2')
      expect(JSON.parse(response.body)['meta']['pagination']['total_count']).not_to be_nil
      expect(JSON.parse(response.body)['meta']['pagination']['total_pages']).not_to be_nil
    end
  end
end

RSpec.shared_examples 'including related resources examples' do |options|
  context "action #{options[:action]} including related resources (associated resource must be created)" do
    let(:perform_specs) { serializer.associations.count > 0 }
    let(:action) { options[:action].to_sym }
    let(:includes) { '*' }
    let(:expected_response_code) do
      case action
      when :index, :show, :update
        200
      when :create
        201
      end
    end

    subject do
      api_login(user)
      case action
      when :index
        get action, parent_param_if_needed.merge(include: includes)
      when :show
        get action, full_params.merge(include: includes)
      when :update
        put action, full_correct_attributes.merge(include: includes)
      when :create
        post action, full_correct_attributes.merge(include: includes)
      end
    end

    context 'with unpermitted filter params' do
      let(:includes) { described_class::UNPERMITTED_FILTER_PARAMS.join(',') }

      it 'does not permit unpermitted filter params' do
        if perform_specs
          expect(described_class::UNPERMITTED_FILTER_PARAMS).to be_present
          subject
          expect(response.status).to eq(expected_response_code)
          expect(JSON.parse(response.body)['included']).to be_nil
        end
      end
    end

    it 'includes one level of related resources' do
      if perform_specs
        subject
        expect(response.status).to eq(expected_response_code)
        expect(JSON.parse(response.body).keys).to include('included')
        included_types = JSON.parse(response.body)['included'].collect { |i| i['type'] }
        expect(included_types).to be_present
      end
    end
  end
end

RSpec.shared_examples 'sparse fieldsets examples' do |options|
  context "action #{options[:action]} sparse fieldsets" do
    let(:action) { options[:action].to_sym }
    let(:resource_type) { serializer._type || resource.class.to_s.underscore.tr('/', '_').pluralize }
    let(:example_attributes) { serializer.attributes.except(:id).keys.first(2).collect(&:to_s) }
    let(:fields) { { resource_type => example_attributes.join(',') } }
    let(:expected_response_code) do
      case action
      when :index, :show, :update
        200
      when :create
        201
      end
    end

    let(:response_attributes) do
      data = JSON.parse(response.body)['data']
      data.is_a?(Array) ? data.first['attributes'] : data['attributes']
    end

    subject do
      api_login(user)
      case action
      when :index
        get action, parent_param_if_needed.merge(fields: fields)
      when :show
        get action, full_params.merge(fields: fields)
      when :update
        put action, full_correct_attributes.merge(fields: fields)
      when :create
        post action, full_correct_attributes.merge(fields: fields)
      end
    end

    it 'supports sparse fieldsets' do
      subject
      expect(response.status).to eq(expected_response_code)
      expect(response_attributes.keys).to match_array(example_attributes)
    end
  end
end

RSpec.shared_examples 'sorting examples' do |options|
  let(:sorting_param_or_created_at) { defined?(sorting_param) ? sorting_param : :created_at }

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
