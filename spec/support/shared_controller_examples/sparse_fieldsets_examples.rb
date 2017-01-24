RSpec.shared_examples 'sparse fieldsets examples' do |options|
  context "action #{options[:action]} sparse fieldsets" do
    let(:action) { options[:action].to_sym }
    let(:example_attributes) { serializer.attributes.except(:id).keys.first(2).collect(&:to_s) }
    let(:fields) { { resource_type => example_attributes.join(',') } }
    let(:expected_response_code) do
      if options[:expected_response_code]
        options[:expected_response_code]
      else
        case action
        when :index, :show, :update
          200
        when :create
          201
        end
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
