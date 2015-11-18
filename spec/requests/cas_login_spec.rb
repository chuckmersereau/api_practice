require 'spec_helper'

describe 'Login with CAS (Relay and Key)' do
  let(:sso_guid) { 'FD3FFDDE-D035-FCY5-B573-7AAB2A7627C5' }
  let(:ticket) { 'ST-26177-6u3xG3gbh6AgSalVerfM-plidma41' }
  let(:person) { create(:person) }

  describe 'login with Relay' do
    it 'does not create a duplicate account if guid differs by case' do
      allow(SiebelDonations::Profile).to receive(:find)
      create(:ccc)

      stub_cas_validate(:relay, 'signin.relaysso.org', relay_validate_body)

      create(:relay_account, remote_id: sso_guid.downcase, person: person,
                             authenticated: true)

      expect do
        get callback_path(:relay)
      end.to_not change(Person::RelayAccount, :count)
      expect(session['signed_in_with']).to eq 'relay'
      expect(session['warden.user.user.key'][0][0]).to eq person.id
    end

    def relay_validate_body
      <<-EOS
      <cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
        <cas:authenticationSuccess>
          <cas:user>test.user@cru.org</cas:user>
          <cas:attributes>
            <lastName>User</lastName>
            <username>test.user@cru.org</username>
            <designation>0123456</designation>
            <ssoGuid>#{sso_guid}</ssoGuid>
            <firstName>Test</firstName>
            <emplid>000123456</emplid>
          </cas:attributes>
        </cas:authenticationSuccess>
      </cas:serviceResponse>
      EOS
    end
  end

  describe 'login with Key' do
    it 'does not create a duplicate account if guid differs by case' do
      create(:key_account, remote_id: sso_guid.downcase, person: person,
                           authenticated: true)

      stub_cas_validate(:key, 'thekey.me', key_validate_body)
      expect do
        get callback_path(:key)
      end.to_not change(Person::KeyAccount, :count)
      expect(session['signed_in_with']).to eq 'key'
      expect(session['warden.user.user.key'][0][0]).to eq person.id
    end

    def key_validate_body
      <<-EOS
      <cas:serviceResponse xmlns:cas='http://www.yale.edu/tp/cas'>
        <cas:authenticationSuccess>
          <cas:user>j@t.co</cas:user>
          <cas:attributes>
            <lastName>User</lastName>
            <email>j@t.co</email>
            <theKeyGuid>#{sso_guid}</theKeyGuid>
            <relayGuid>#{sso_guid}</relayGuid>
            <firstName>Test</firstName>
            <ssoGuid>#{sso_guid}</ssoGuid>
          </cas:attributes>
        </cas:authenticationSuccess>
      </cas:serviceResponse>
      EOS
    end
  end

  def stub_cas_validate(service, host, body)
    stub_request(:get, cas_validate_url(service, host)).to_return(body: body)
  end

  def cas_validate_url(service, host)
    "https://#{host}/cas/serviceValidate?"\
      "service=https://localhost:3000/auth/#{service}/callback?"\
      'origin=login%26url=http%253A%252F%252Flocalhost%253A3000%252Flogin&'\
      "ticket=#{ticket}"
  end

  def callback_path(service)
    "/auth/#{service}/callback?origin=login&"\
      'url=http%3A%2F%2Flocalhost%3A3000%2Flogin&'\
      "ticket=#{ticket}"
  end
end
