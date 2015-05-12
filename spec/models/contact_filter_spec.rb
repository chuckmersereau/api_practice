require 'spec_helper'

describe ContactFilter do
  context '#filter' do
    it 'filters contacts with newsletter = Email and state' do
      c = create(:contact, send_newsletter: 'Email')
      a = create(:address, addressable: c)
      p = create(:person)
      c.people << p
      create(:email_address, person: p)
      cf = ContactFilter.new(newsletter: 'email', state: a.state)
      cf.filter(Contact).includes([{ primary_person: [:facebook_account, :primary_picture] },
                                   :tags, :primary_address,
                                   { people: :primary_phone_number }]).should == [c]
    end

    it 'filters contacts with statuses null and another' do
      nil_status = create(:contact, status: nil)
      has_status = create(:contact, status: 'Never Contacted')
      cf = ContactFilter.new(status: ['null', 'Never Contacted'])

      filtered_contacts = cf.filter(Contact)
      filtered_contacts.should include nil_status
      filtered_contacts.should include has_status
    end

    it 'filters by person name on wildcard search with and without comma' do
      c = create(:contact, name: 'Doe, John')
      p = create(:person, first_name: 'John', last_name: 'Doe')
      c.people << p
      expect(ContactFilter.new(wildcard_search: 'john doe').filter(Contact)).to include c
      expect(ContactFilter.new(wildcard_search: ' Doe,  John ').filter(Contact)).to include c
    end

    it 'does not cause an error if wildcard search less than two words with or without comma' do
      expect { ContactFilter.new(wildcard_search: 'john').filter(Contact) }.to_not raise_error
      expect { ContactFilter.new(wildcard_search: '').filter(Contact) }.to_not raise_error
      expect { ContactFilter.new(wildcard_search: ',').filter(Contact) }.to_not raise_error
      expect { ContactFilter.new(wildcard_search: 'doe,').filter(Contact) }.to_not raise_error
    end

    it 'filters by commitment received' do
      received = create(:contact, pledge_received: true)
      not_received = create(:contact, pledge_received: false)

      cf = ContactFilter.new(pledge_received: 'true')
      filtered_contacts = cf.filter(Contact)
      expect(filtered_contacts).to eq [received]

      cf = ContactFilter.new(pledge_received: 'false')
      filtered_contacts = cf.filter(Contact)
      expect(filtered_contacts).to eq [not_received]

      cf = ContactFilter.new(pledge_received: '')
      filtered_contacts = cf.filter(Contact)
      expect(filtered_contacts.length).to be 2
    end

    it 'filters by contact details' do
      has_email = create(:contact)
      has_email.people << create(:person)
      has_email.people << create(:person)
      has_email.primary_or_first_person.email_addresses << create(:email_address)
      no_email = create(:contact)
      no_email.people << create(:person)
      no_email.primary_or_first_person.email_addresses << create(:email_address, historic: true)

      cf = ContactFilter.new(contact_info_email: 'Yes')
      filtered_contacts = cf.filter(Contact)
      expect(filtered_contacts).to eq [has_email]

      cf = ContactFilter.new(contact_info_email: 'No')
      filtered_contacts = cf.filter(Contact)
      expect(filtered_contacts).to eq [no_email]
    end

    it 'filters by contact address present' do
      has_address = create(:contact)
      has_address.addresses << create(:address)
      has_address.addresses << create(:address, historic: true)
      no_address = create(:contact)
      historic_address_contact = create(:contact)
      historic_address_contact.addresses << create(:address, historic: true)

      cf = ContactFilter.new(contact_info_addr: 'Yes')
      filtered_contacts = cf.filter(Contact)
      expect(filtered_contacts).to include has_address
      expect(filtered_contacts).to_not include no_address
      expect(filtered_contacts).to_not include historic_address_contact

      cf = ContactFilter.new(contact_info_addr: 'No', contact_info_email: 'No')
      no_address_contacts = cf.filter(Contact)
      expect(no_address_contacts).to_not include has_address
      expect(no_address_contacts).to include no_address
      expect(no_address_contacts).to include historic_address_contact
    end
  end
end
