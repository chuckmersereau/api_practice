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
        filter_value = ''

        if CastedValueValidator::DATE_FIELD_ENDINGS.any? { |ending| filter.to_s.end_with?(ending) }
          filter_value = Date.current
        end

        get :index, filter: { filter => filter_value }

        expect(response.status).to eq(200), invalid_status_detail

        if CastedValueValidator::DATE_FIELD_ENDINGS.any? { |ending| filter.to_s.end_with?(ending) }
          filter_range = filter_value.to_datetime.beginning_of_day..filter_value.to_datetime.end_of_day
          expect(JSON.parse(response.body)['meta']['filter'][filter]).to eq(filter_range.to_s)
        else
          expect(JSON.parse(response.body)['meta']['filter'][filter]).to eq('')
        end
      end
    end
  end
end
