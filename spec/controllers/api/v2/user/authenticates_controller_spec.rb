require 'rails_helper'

RSpec.describe Api::V2::User::AuthenticatesController, type: :controller do
  let!(:user)            { create(:user) }
  let(:response_body)    { JSON.parse(response.body) }
  let(:valid_cas_ticket) { 'ST-314971-9fjrd0HfOINCehJ5TKXX-cas2a' }
  let(:service)          { 'http://test.host/api/v2/user/authenticate' }

  let(:request_data) do
    {
      id: nil,
      type: 'authenticate',
      attributes: {
        cas_ticket: valid_cas_ticket
      }
    }
  end

  describe '#create' do
    context 'valid cas ticket' do
      let!(:validator) do
        CasTicketValidatorService.new(ticket: valid_cas_ticket, service: service)
      end

      before do
        stub_request(
          :get,
          "#{ENV['CAS_BASE_URL']}/p3/serviceValidate?service=#{service}&ticket=#{valid_cas_ticket}"
        ).to_return(
          status: 200,
          body: File.open(
            Rails.root.join('spec', 'fixtures', 'cas', 'successful_ticket_validation_response_body.xml')
          ).read
        )

        user.relay_accounts << create(:relay_account, relay_remote_id: 'B163530-7372-551R-KO83-1FR05534129F')

        allow(UserFromCasService)
          .to receive(:find_or_create)
          .with(validator.attributes)
          .and_return(user)

        travel_to(Time.now)
      end

      after { travel_back }

      subject { post :create, data: request_data }

      it 'returns success' do
        subject
        expect(response.status).to eq(200)
      end

      it 'responds with a valid json web token' do
        subject

        json_web_token = response_body['data']['attributes']['json_web_token']
        decoded_web_token = JsonWebToken.decode(json_web_token)

        expect(json_web_token).to be_present
        expect(User.find_by(id: decoded_web_token['user_id']).id).to eq user.id
        expect(decoded_web_token['exp']).to eq 30.days.from_now.utc.to_i
      end

      it 'updates the user tracked fields' do
        user.update_columns(current_sign_in_at: 1.year.ago, last_sign_in_at: 2.years.ago, sign_in_count: 2)
        expect { subject }.to change { user.current_sign_in_at }.to(Time.now)
        expect(user.last_sign_in_at).to eq(1.year.ago)
        expect(user.sign_in_count).to eq(3)
      end
    end

    context 'invalid ticket' do
      before do
        user.relay_accounts << create(:relay_account, relay_remote_id: 'B163530-7372-551R-KO83-1FR05534129F')
        stub_request(
          :get,
          "#{ENV['CAS_BASE_URL']}/p3/serviceValidate?"\
          "service=http://test.host/api/v2/user/authenticate&ticket=#{valid_cas_ticket}"
        ).to_return(
          status: 200,
          body: File.open(
            Rails.root.join('spec', 'fixtures', 'cas', 'invalid_ticket_validation_response_body.xml')
          ).read
        )
        post :create, data: request_data
      end

      it 'returns unauthorized' do
        expect(response.status).to eq(401)
      end

      it 'returns error details in the json body' do
        expect(response_body['data']).to be_nil
        expect(response_body['errors'].size).to eq 1
        expect(response_body['errors'].first['status']).to eq '401'
        expect(response_body['errors'].first['detail']).to eq(
          "INVALID_TICKET: Ticket '#{valid_cas_ticket}' not recognized"
        )
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
        expect(response_body['errors'].first['status']).to eq '400'
        expect(response_body['errors'].first['detail']).to eq(
          'Expected a cas_ticket to be provided in the attributes'
        )
      end
    end
  end
end
