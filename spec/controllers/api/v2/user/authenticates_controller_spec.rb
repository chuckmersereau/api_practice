require 'rails_helper'

RSpec.describe Api::V2::User::AuthenticatesController, type: :controller do
  let!(:user) { create(:user) }
  let(:response_body) { JSON.parse(response.body) }
  let(:valid_cas_ticket) { 'ST-314971-9fjrd0HfOINCehJ5TKXX-cas2a' }
  let(:request_data) do
    {
      id: nil,
      type: 'authenticate',
      attributes: { cas_ticket: valid_cas_ticket }
    }
  end

  describe '#create' do
    context 'valid cas ticket' do
      before do
        user.relay_accounts << create(:relay_account, relay_remote_id: 'B163530-7372-551R-KO83-1FR05534129F')
        stub_request(:get, "https://thekey.me/cas/p3/serviceValidate?service=http://test.host/api/v2/user/authenticate&ticket=#{valid_cas_ticket}")
          .to_return(status: 200, body: File.open(Rails.root.join('spec', 'fixtures', 'cas', 'successful_ticket_validation_response_body.xml')).read)
        post :create, data: request_data
      end

      it 'returns success' do
        expect(response.status).to eq(200)
      end

      it 'responds with a valid json web token' do
        json_web_token = response_body['data']['attributes']['json_web_token']
        expect(json_web_token).to be_present
        expect(User.find(JsonWebToken.decode(json_web_token)['user_id']).id).to eq user.id
      end
    end

    context 'invalid ticket' do
      before do
        user.relay_accounts << create(:relay_account, relay_remote_id: 'B163530-7372-551R-KO83-1FR05534129F')
        stub_request(:get, "https://thekey.me/cas/p3/serviceValidate?service=http://test.host/api/v2/user/authenticate&ticket=#{valid_cas_ticket}")
          .to_return(status: 200, body: File.open(Rails.root.join('spec', 'fixtures', 'cas', 'invalid_ticket_validation_response_body.xml')).read)
        post :create, data: request_data
      end

      it 'returns unauthorized' do
        expect(response.status).to eq(401)
      end

      it 'returns error details in the json body' do
        expect(response_body['data']).to be_nil
        expect(response_body['errors'].size).to eq 1
        expect(response_body['errors'].first['status']).to eq 'unauthorized'
        expect(response_body['errors'].first['detail']).to eq "INVALID_TICKET: Ticket '#{valid_cas_ticket}' not recognized"
      end
    end

    context 'missing ticket' do
      before do
        post :create
      end

      it 'returns bad request' do
        expect(response.status).to eq(400)
      end

      it 'returns error details in the json body' do
        expect(response_body['data']).to be_nil
        expect(response_body['errors'].size).to eq 1
        expect(response_body['errors'].first['status']).to eq 'bad_request'
        expect(response_body['errors'].first['detail']).to eq 'Expected a cas_ticket to be provided in the attributes'
      end
    end
  end
end
