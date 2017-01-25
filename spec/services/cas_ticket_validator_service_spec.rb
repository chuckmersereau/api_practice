require 'spec_helper'

RSpec.describe CasTicketValidatorService, type: :service do
  let!(:service) { CasTicketValidatorService.new(ticket: 'ST-314971-9fjrd0HfOINCehJ5TKXX-cas2a', service: 'http://my.service') }

  after do
    ENV['CAS_BASE_URL'] = 'https://thekey.me/cas'
  end

  describe '#initialize' do
    it 'initializes attributes successfully' do
      service = CasTicketValidatorService.new(ticket: 'test-ticket', service: 'http://my.service')
      expect(service.ticket).to eq('test-ticket')
      expect(service.service).to eq('http://my.service')
    end
  end

  context 'invalid ticket' do
    before do
      stub_request(:get, 'https://thekey.me/cas/p3/serviceValidate?service=http://my.service&ticket=ST-314971-9fjrd0HfOINCehJ5TKXX-cas2a')
        .to_return(status: 200, body: File.open(Rails.root.join('spec', 'fixtures', 'cas', 'invalid_ticket_validation_response_body.xml')).read)
    end

    describe '#validate' do
      it 'raises an authentication error with a message' do
        expect { service.validate }.to raise_error Exceptions::AuthenticationError, "INVALID_TICKET: Ticket 'ST-314971-9fjrd0HfOINCehJ5TKXX-cas2a' not recognized"
      end
    end

    describe '#attribute' do
      it 'does not return sso guid' do
        expect(service.attribute('ssoGuid')).to be_nil
      end
    end
  end

  context 'valid ticket' do
    before do
      stub_request(:get, 'https://thekey.me/cas/p3/serviceValidate?service=http://my.service&ticket=ST-314971-9fjrd0HfOINCehJ5TKXX-cas2a')
        .to_return(status: 200, body: File.open(Rails.root.join('spec', 'fixtures', 'cas', 'successful_ticket_validation_response_body.xml')).read)
    end

    describe '#validate' do
      it 'does not raise any error' do
        expect { service.validate }.to_not raise_error
      end

      it 'returns true' do
        expect(service.validate).to eq true
      end
    end

    describe '#attribute' do
      it 'returns the sso guid of the validated user' do
        expect(service.attribute('ssoGuid')).to eq 'B163530-7372-551R-KO83-1FR05534129F'
      end

      it 'returns nil if the attribute does not exist' do
        expect(service.attribute('wut')).to be_nil
      end
    end
  end

  describe 'depends on CAS_BASE_URL environment variable' do
    it 'raises an error if the variable is not present' do
      ENV['CAS_BASE_URL'] = nil
      expect { service.validate }.to raise_error(RuntimeError, 'expected CAS_BASE_URL environment variable to be present and using https')
    end

    it 'raises an error if the url is not secure' do
      ENV['CAS_BASE_URL'] = 'http://thekey.me/cas'
      expect { service.validate }.to raise_error(RuntimeError, 'expected CAS_BASE_URL environment variable to be present and using https')
    end
  end
end
