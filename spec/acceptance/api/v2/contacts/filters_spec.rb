require 'rails_helper'
require 'rspec_api_documentation/dsl'

resource 'Contacts > Filters' do
  include_context :json_headers
  documentation_scope = :contacts_api_filters

  let!(:user)         { create(:user_with_account) }
  context 'authorized user' do
    before { api_login(user) }

    get '/api/v2/contacts/filters' do
      example 'Filter [LIST]', document: documentation_scope do
        explanation 'List of Contact Filters'
        do_request
        filters_displayed = json_response['data'].map do |filter|
          filter['type'].gsub('contact_filter_', '').camelize
        end
        expect(Contact::Filterer::FILTERS_TO_DISPLAY.map(&:pluralize)).to include(*filters_displayed)
        expect(response_status).to eq 200
      end
    end
  end
end
