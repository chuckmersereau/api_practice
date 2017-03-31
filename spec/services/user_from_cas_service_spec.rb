require 'rails_helper'

RSpec.describe UserFromCasService, type: :service do
  before { stub_cas_requests }

  let(:validator) { build_validator_service }
  let(:service)   { UserFromCasService.new(validator.attributes) }

  describe '#initialize' do
    it 'initializes with attributes from the CasTicketValidatorService' do
      expect(service.cas_attributes).to eq validator.attributes
    end
  end

  describe '#guids' do
    it 'returns the ssoGuid' do
      expected_guids = ['B163530-7372-551R-KO83-1FR05534129F']

      expect(service.guids).to match expected_guids
    end
  end

  describe '#omniauth_attributes_hash' do
    it 'returns cas_attributes in the same format omniauth would return them' do
      expected_attributes = {
        provider: 'key',
        uid: 'cas.user@internet.com',
        extra: {
          user: 'cas.user@internet.com',
          attributes: [
            {
              ssoGuid: 'B163530-7372-551R-KO83-1FR05534129F',
              firstName: 'Cas',
              lastName: 'User',
              theKeyGuid: 'B163530-7372-551R-KO83-1FR05534129F',
              relayGuid: 'B163530-7372-551R-KO83-1FR05534129F',
              email: 'cas.user@internet.com'
            }
          ]
        }
      }

      expect(service.omniauth_attributes_hash)
        .to eq Hashie::Mash.new(expected_attributes)
    end
  end

  describe '#find_or_create' do
    context 'When a User with the GUID already exists' do
      let!(:user) do
        create(:user_with_account).tap do |user|
          relay_account = user.relay_accounts.first

          relay_account.update(relay_remote_id: service.guids.first)
        end
      end

      it 'returns the User' do
        expect(service.find_or_create).to eq user
      end
    end

    context "When a User with the GUID DOESN'T exist" do
      let(:user) { double('user') }

      before do
        allow(Person::KeyAccount)
          .to receive(:create_user_from_auth)
          .with(service.omniauth_attributes_hash)
          .and_return(user)

        expect(Person::KeyAccount)
          .to receive(:find_or_create_from_auth)
          .with(service.omniauth_attributes_hash, user)
      end

      it 'delegates to the KeyAccount to make the user' do
        expect(service.find_or_create).to eq user
      end
    end
  end

  private

  def build_validator_service
    CasTicketValidatorService.new(ticket: mock_ticket, service: mock_service)
  end

  def mock_service
    'http://my.service'
  end

  def mock_ticket
    'ST-314971-9fjrd0HfOINCehJ5TKXX-cas2a'
  end

  def stub_cas_requests
    url           = "https://thekey.me/cas/p3/serviceValidate?service=#{mock_service}&ticket=#{mock_ticket}"
    data_filepath = Rails.root.join('spec', 'fixtures', 'cas', 'successful_ticket_validation_response_body.xml')
    response_body = File.read(data_filepath)

    stub_request(:get, url).to_return(status: 200, body: response_body)
  end
end
