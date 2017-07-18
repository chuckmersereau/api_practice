require 'rails_helper'

describe WebRouter do
  describe '.env' do
    it 'returns the current environment' do
      expect(described_class.env).to eq('test')
    end
  end

  describe '.host' do
    context 'development environment' do
      before { expect(WebRouter).to receive(:env).and_return('development') }

      it 'returns the expected host' do
        expect(described_class.host).to eq('localhost:8080')
      end
    end

    context 'staging environment' do
      before { expect(WebRouter).to receive(:env).and_return('staging') }

      it 'returns the expected host' do
        expect(described_class.host).to eq('stage.mpdx.org')
      end
    end

    %w(production test something).each do |env|
      context "#{env} environment" do
        before { expect(WebRouter).to receive(:env).and_return(env) }

        it 'returns the expected host' do
          expect(described_class.host).to eq('mpdx.org')
        end
      end
    end
  end

  describe '.protocol' do
    context 'development environment' do
      before { expect(WebRouter).to receive(:env).and_return('development') }

      it 'returns the expected protocol' do
        expect(described_class.protocol).to eq('http')
      end
    end

    %w(production staging test something).each do |env|
      context "#{env} environment" do
        before { expect(WebRouter).to receive(:env).and_return(env) }

        it 'returns the expected protocol' do
          expect(described_class.protocol).to eq('https')
        end
      end
    end
  end

  describe '.base_url' do
    it 'returns the expected url' do
      expect(described_class.base_url).to eq('https://mpdx.org')
    end
  end

  describe '.account_list_invite_url' do
    let(:invite) { double(account_list: double(uuid: 'account_list_uuid'), uuid: 'invite_uuid', code: 'invite_code') }

    it 'returns the expected url' do
      expect(described_class.account_list_invite_url(invite)).to eq('https://mpdx.org/account_lists/account_list_uuid/accept_invite/invite_uuid?code=invite_code')
    end
  end

  describe '.integration_preferences_url' do
    it 'returns the expected url' do
      expect(described_class.integration_preferences_url('asdf')).to eq('https://mpdx.org/preferences/integrations?selectedTab=asdf')
    end
  end

  describe '.notifications_preferences_url' do
    it 'returns the expected url' do
      expect(described_class.notifications_preferences_url).to eq('https://mpdx.org/preferences/notifications')
    end
  end

  describe '.contact_url' do
    let(:contact) { double(uuid: 'contact_uuid') }

    it 'returns the expected url' do
      expect(described_class.contact_url(contact)).to eq('https://mpdx.org/contacts/contact_uuid')
    end
  end

  describe '.person_url' do
    let(:person) { double(uuid: 'person_uuid', contact: double(uuid: 'contact_uuid')) }

    it 'returns the expected url' do
      expect(described_class.person_url(person)).to eq('https://mpdx.org/contacts/contact_uuid?personId=person_uuid')
    end
  end
end
