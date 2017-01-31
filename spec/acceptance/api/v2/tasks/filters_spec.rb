require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Filters' do
  include_context :json_headers
  let!(:user)         { create(:user_with_account) }
  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/tasks/filters' do
      example 'Filter [LIST]', document: :tasks do
        explanation 'List of Task Filters'
        do_request
        filters_displayed = json_response['data'].map do |filter|
          filter['type'].gsub('task_filter_', '').camelize
        end
        expect(Task::Filterer::FILTERS_TO_DISPLAY.map(&:pluralize)).to include(*filters_displayed)
        expect(response_status).to eq 200
      end
    end
  end
end
