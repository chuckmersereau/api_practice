require 'spec_helper'
require 'rspec_api_documentation/dsl'

resource 'Address' do
  let!(:user) { create(:user_with_full_account) }
  let!(:resource) { create(:address, addressable: contact) }

  let(:resource_type) { 'addresses' }
  let(:contact) { create(:contact, account_list: user.account_lists.first) }
  let(:contact_id) { contact.id }
  let(:id) { resource.id }
  let(:new_resource) { build(:address, addressable: contact).attributes }
  let(:form_data) { build_data(new_resource) }

  context 'authorized user' do
    before do
      api_login(user)
    end

    get '/api/v2/contacts/:contact_id/addresses' do
      example_request 'get addresses' do
        explanation 'List of Addresses associated to the contact'
        check_collection_resource 1
        expect(status).to eq 200
      end
    end

    get '/api/v2/contacts/:contact_id/addresses/:id' do
      with_options scope: [:data, :attributes] do
        response_field :city, 'City', 'Type' => 'String'
        response_field :country, 'Country', 'Type' => 'String'
        response_field :end_date, 'End Date', 'Type' => 'String'
        response_field :geo, 'Geo', 'Type' => 'String'
        response_field :historic, 'Historic', 'Type' => 'Boolean'
        response_field :location, 'Location', 'Type' => 'String'
        response_field :postal_code, 'Postal Code', 'Type' => 'String'
        response_field :primary_mailing_address, 'Primary Mailing Address', 'Type' => 'Boolean'
        response_field :start_date, 'Start Date', 'Type' => 'String'
        response_field :state, 'State', 'Type' => 'String'
        response_field :street, 'Street', 'Type' => 'String'
      end

      example_request 'get address' do
        check_resource
        expect(status).to eq 200
      end
    end

    post '/api/v2/contacts/:contact_id/addresses' do
      with_options required: true, scope: [:data, :attributes] do
        parameter :city, 'City'
        parameter :country, 'Country'
        parameter :end_date, 'End Date'
        parameter :location, 'Location'
        parameter :metro_area, 'Metro Area'
        parameter :postal_code, 'Postal Code'
        parameter :primary_mailing_address, 'Primary Mailing Address'
        parameter :region, 'Region'
        parameter :remote_id, 'Remote ID'
        parameter :seasonal, 'Seasonal'
        parameter :start_date, 'Start Date'
        parameter :state, 'State'
        parameter :street, 'Street'
      end

      example 'create address' do
        do_request data: form_data
        expect(resource_object['street']).to(be_present) && eq(new_resource['street'])
        expect(status).to eq 200
      end
    end

    put '/api/v2/contacts/:contact_id/addresses/:id' do
      with_options required: true, scope: [:data, :attributes] do
        parameter :city, 'City'
        parameter :country, 'Country'
        parameter :end_date, 'End Date'
        parameter :location, 'Location'
        parameter :metro_area, 'Metro Area'
        parameter :postal_code, 'Postal Code'
        parameter :primary_mailing_address, 'Primary Mailing Address'
        parameter :region, 'Region'
        parameter :remote_id, 'Remote ID'
        parameter :seasonal, 'Seasonal'
        parameter :start_date, 'Start Date'
        parameter :state, 'State'
        parameter :street, 'Street'
      end

      example 'update address' do
        do_request data: form_data
        expect(resource_object['street']).to(be_present) && eq(new_resource['street'])
        expect(status).to eq 200
      end
    end

    delete '/api/v2/contacts/:contact_id/addresses/:id' do
      example_request 'delete address' do
        expect(status).to eq 200
      end
    end
  end
end
