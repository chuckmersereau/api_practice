RSpec.shared_examples 'including related resources examples' do |options|
  context "action #{options[:action]} including related resources" do
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
        if serializer.associations.count > 0
          expect(described_class::UNPERMITTED_FILTER_PARAMS).to be_present
          subject
          expect(response.status).to eq(expected_response_code)
          expect(JSON.parse(response.body)['included']).to be_nil
        end
      end
    end

    it 'includes one level of related resources' do
      if serializer.associations.count > 0
        subject
        expect(response.status).to eq(expected_response_code)
        expect(JSON.parse(response.body).keys).to include('included')
        included_types = JSON.parse(response.body)['included'].collect { |i| i['type'] }
        expect(included_types).to be_present
      end
    end
  end
end
