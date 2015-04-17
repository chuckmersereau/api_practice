require 'spec_helper'

describe PrayerLettersAccount do
  let(:pla) { create(:prayer_letters_account) }
  let(:contact) { create(:contact, account_list: pla.account_list, send_newsletter: 'Both') }
  let(:params) do
    { city: 'Fremont', external_id: contact.id.to_s, file_as: 'Doe, John', greeting: '',
      name: 'John Doe', postal_code: '94539', state: 'CA', street: '123 Somewhere St' }
  end

  context '#get_response' do
    it 'marks token as invalid if response is a 401 for OAuth2' do
      stub_request(:get, %r{https:\/\/www\.prayerletters\.com\/*}).to_return(status: 401)
      pla = create(:prayer_letters_account_oauth2)
      pla.should_receive(:handle_bad_token).and_return('{}')
      pla.contacts
    end

    it 'marks token as invalid if response is a 403 for OAuth2' do
      stub_request(:get, %r{https:\/\/www\.prayerletters\.com\/*}).to_return(status: 403)
      pla = create(:prayer_letters_account_oauth2)
      pla.should_receive(:handle_bad_token).and_return('{}')
      pla.contacts
    end

    it 'uses OAuth2 if possible' do
      stub_request(:get, 'https://www.prayerletters.com/api/v1/contacts')
        .with(headers: { 'Authorization' => 'Bearer test_oauth2_token' })
        .to_return(body: '{}')
      pla_oauth2 = create(:prayer_letters_account_oauth2)
      pla_oauth2.contacts
    end

    it 'uses OAuth1 if no oauth2_token present' do
      stub_request(:get, 'https://www.prayerletters.com/api/v1/contacts')
        .to_return(body: '{}')
      pla_oauth1 = create(:prayer_letters_account)
      pla_oauth1.contacts
    end
  end

  context '#handle_bad_token' do
    it 'sends an email to the account users' do
      AccountMailer.should_receive(:prayer_letters_invalid_token).with(an_instance_of(AccountList)).and_return(double(deliver: true))

      expect do
        pla.handle_bad_token
      end.to raise_exception(PrayerLettersAccount::AccessError)
    end

    it 'sets valid_token to false' do
      AccountMailer.stub(:prayer_letters_invalid_token).and_return(double(deliver: true))

      expect do
        pla.handle_bad_token
      end.to raise_exception(PrayerLettersAccount::AccessError)

      expect(pla.valid_token).to be_false
    end
  end

  context '#update_contact' do
    before do
      contact.addresses << create(:address, primary_mailing_address: true)
      contact.update(prayer_letters_id: 'c1', send_newsletter: 'Both', prayer_letters_params: nil)
    end

    it 'calls the prayer letters api to create a contact and sets cached params value' do
      stub = stub_request(:post, 'https://www.prayerletters.com/api/v1/contacts/c1')
             .with(body: params, headers: { 'Authorization' => 'Bearer MyString' }).to_return(status: 204)

      pla.update_contact(contact)
      expect(contact.prayer_letters_id).to eq('c1')
      params[:external_id] = params[:external_id].to_i
      expect(contact.prayer_letters_params).to eq(params)
      expect(stub).to have_been_requested
    end

    it 'does not call the api if the contact params are the same as the cached value' do
      params[:external_id] = params[:external_id].to_i
      contact.update(prayer_letters_params: params)
      expect(pla).to_not receive(:get_request)
      pla.update_contact(contact)
    end

    def stub_update_error(code)
      stub = stub_request(:post, 'https://www.prayerletters.com/api/v1/contacts/c1').to_return(status: code)
      yield
      expect(stub).to have_been_requested
    end

    it 're-subscribes the contact list on 404' do
      stub_update_error(404) do
        expect(pla).to receive(:queue_subscribe_contacts)
        pla.update_contact(contact)
      end
    end

    it 're-subscribes the contact list on 410' do
      stub_update_error(410) do
        expect(contact.reload.prayer_letters_params).to eq({})
        expect(pla).to receive(:queue_subscribe_contacts)
        pla.update_contact(contact)
      end
    end
  end

  context '#create_contact' do
    it 'calls the prayer letters api to create a contact and sets cached params value' do
      contact.addresses << create(:address)

      params = { city: 'Fremont', external_id: contact.id.to_s, file_as: 'Doe, John', greeting: '',
                 name: 'John Doe', postal_code: '94539', state: 'CA', street: '123 Somewhere St' }
      stub = stub_request(:post, 'https://www.prayerletters.com/api/v1/contacts')
             .with(body: params, headers: { 'Authorization' => 'Bearer MyString' })
             .to_return(body: '{"contact_id": "c1"}')

      pla.create_contact(Contact.find(contact.id))
      contact.reload
      expect(contact.prayer_letters_id).to eq('c1')
      params[:external_id] = params[:external_id].to_i
      expect(contact.prayer_letters_params).to eq(params)
      expect(stub).to have_been_requested
    end

    it 'does not raise an error on a 400 bad request code but logs it via Airbrake' do
      missing_name_body = <<-EOS
        {
            "status": 400,
            "error": "contacts.missing_name",
            "message": "A contact must have a name or company."
        }
      EOS
      stub_request(:post, 'https://www.prayerletters.com/api/v1/contacts').to_return(body: missing_name_body, status: 400)

      expect(Airbrake).to receive(:raise_or_notify)
      pla.create_contact(contact)
    end
  end

  context '#subscribe_contacts' do
    it 'syncronizes a contact even if it has no people' do
      contact.update(prayer_letters_id: 1)
      contact.addresses << create(:address)
      expect(contact.people.count).to eq(0)

      contacts_body = '{"contacts":[{"name":"John Doe","greeting":"","file_as":"Doe, John","contact_id":"1",'\
        '"address":{"street":"123 Somewhere St","city":"Fremont","state":"CA","postal_code":"94539",'\
        '"country":"United States"},"external_id":' + contact.id.to_s +  '}]}'

      stub = stub_request(:put, 'https://www.prayerletters.com/api/v1/contacts')
             .with(body: contacts_body, headers: { 'Authorization' => 'Bearer MyString' })

      expect(pla).to receive(:import_list)
      pla.subscribe_contacts
      expect(stub).to have_been_requested
    end

    it 'clears the prayer letters params for removed contacts so they can be re-added later' do
      stub_request(:put, 'https://www.prayerletters.com/api/v1/contacts')
        .with(headers: { 'Authorization' => 'Bearer MyString' })
      expect(pla).to receive(:import_list)

      contact.update_columns(send_newsletter: false, prayer_letters_params: { old: 'old values' })
      pla.subscribe_contacts
      contact.reload
      expect(contact.prayer_letters_params).to be_blank
      expect(contact.prayer_letters_id).to be_nil
    end
  end

  context '#import_list' do
    it 'retrieves the prayer letters list and updates contacts with prayer_letters_id' do
      contacts_body = '{"contacts":[{"name":"John Doe","greeting":"","file_as":"Doe, John","contact_id":"c1",'\
        '"address":{"street":"123 Somewhere St","city":"Fremont","state":"CA","postal_code":"94539",'\
        '"country":"United States"},"external_id":' + contact.id.to_s +  '}]}'

      stub = stub_request(:get, 'https://www.prayerletters.com/api/v1/contacts')
             .with(headers: { 'Authorization' => 'Bearer MyString' }).to_return(body: contacts_body)

      pla.import_list
      contact.reload
      expect(contact.prayer_letters_id).to eq('c1')
      expect(contact.prayer_letters_params).to be_blank
      expect(stub).to have_been_requested
    end
  end

  context '#delete_contact' do
    it 'calls the prayer letters api to delete and sets prayer letters info to blanks' do
      contact.update_columns(prayer_letters_id: 'c1', prayer_letters_params: params)

      stub = stub_request(:delete, 'https://www.prayerletters.com/api/v1/contacts/c1')
             .with(headers: { 'Authorization' => 'Bearer MyString' })

      pla.delete_contact(contact)
      expect(stub).to have_been_requested
      contact.reload
      expect(contact.prayer_letters_id).to be_nil
      expect(contact.prayer_letters_params).to be_blank
    end
  end

  context '#delete_all_contacts' do
    it 'calls the prayer letters api to delete all and sets prayer letters info to blanks' do
      contact.update(prayer_letters_id: 'c1', prayer_letters_params: params)

      stub = stub_request(:delete, 'https://www.prayerletters.com/api/v1/contacts')
             .with(headers: { 'Authorization' => 'Bearer MyString' })

      pla.delete_all_contacts
      expect(stub).to have_been_requested
      contact.reload
      expect(contact.prayer_letters_id).to be_nil
      expect(contact.prayer_letters_params).to be_blank
    end
  end
end
