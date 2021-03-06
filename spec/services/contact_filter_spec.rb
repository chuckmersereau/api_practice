require 'rails_helper'

describe ContactFilter do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  describe 'filters' do
    it 'filters by comma separated ids' do
      c1 = create(:contact)
      c2 = create(:contact)
      create(:contact)
      filtered = ContactFilter.new(ids: "#{c1.id},#{c2.id}").filter(Contact, account_list)
      expect(filtered.count).to eq(2)
      expect(filtered).to include(c1)
      expect(filtered).to include(c2)
    end

    it 'allows all if ids blank' do
      create(:contact)
      expect(ContactFilter.new(ids: '').filter(Contact, account_list).count).to eq(1)
    end

    it 'can handle a list of blank elements ",,"' do
      expect { ContactFilter.new(ids: ',,').filter(Contact, account_list).count }.to_not raise_error
    end

    it 'filters contacts with newsletter = Email and state' do
      c = create(:contact, send_newsletter: 'Email')
      a = create(:address, addressable: c)
      p = create(:person)
      c.people << p
      create(:email_address, person: p)
      cf = ContactFilter.new(newsletter: 'email', state: a.state)
      expect(
        cf.filter(Contact, user.account_lists.order(:created_at).first)
          .includes([{ primary_person: [:facebook_account, :primary_picture] },
                     :tags, :primary_address, { people: :primary_phone_number }])
      ).to eq([c])
    end

    it 'filters contacts with statuses null and another' do
      nil_status = create(:contact, status: nil)
      has_status = create(:contact, status: 'Never Contacted')
      cf = ContactFilter.new(status: ['null', 'Never Contacted'])

      filtered_contacts = cf.filter(Contact, account_list)
      expect(filtered_contacts).to include nil_status
      expect(filtered_contacts).to include has_status
    end

    it 'filters by person name on wildcard search with and without comma' do
      c = create(:contact, name: 'Doe, John')
      p = create(:person, first_name: 'John', last_name: 'Doe')
      c.people << p
      expect(ContactFilter.new(wildcard_search: 'john doe').filter(Contact, account_list)).to include c
      expect(ContactFilter.new(wildcard_search: ' Doe,  John ').filter(Contact, account_list)).to include c
    end

    it 'does not cause an error if wildcard search less than two words with or without comma' do
      expect { ContactFilter.new(wildcard_search: 'john').filter(Contact, account_list) }.to_not raise_error
      expect { ContactFilter.new(wildcard_search: '').filter(Contact, account_list) }.to_not raise_error
      expect { ContactFilter.new(wildcard_search: ',').filter(Contact, account_list) }.to_not raise_error
      expect { ContactFilter.new(wildcard_search: 'doe,').filter(Contact, account_list) }.to_not raise_error
    end

    it 'filters by commitment received' do
      received = create(:contact, pledge_received: true)
      not_received = create(:contact, pledge_received: false)

      cf = ContactFilter.new(pledge_received: 'true')
      filtered_contacts = cf.filter(Contact, account_list)
      expect(filtered_contacts).to eq [received]

      cf = ContactFilter.new(pledge_received: 'false')
      filtered_contacts = cf.filter(Contact, account_list)
      expect(filtered_contacts).to eq [not_received]

      cf = ContactFilter.new(pledge_received: '')
      filtered_contacts = cf.filter(Contact, account_list)
      expect(filtered_contacts.length).to be 2
    end

    context 'pledge frequency' do
      it "doesn't error when passed a 'null'" do
        received = create(:contact, pledge_received: true)

        cf = ContactFilter.new(pledge_frequencies: 'null', received: true)
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to eq [received]
      end
    end

    context '#contact_info_email' do
      let!(:has_email) do
        c = create(:contact)
        c.people << create(:person)
        c.people << create(:person)
        c.primary_or_first_person.email_addresses << create(:email_address)
        c
      end
      let!(:no_email) do
        c = create(:contact)
        c.people << create(:person)
        c.primary_or_first_person.email_addresses << create(:email_address, historic: true)
        c
      end

      it 'filters when looking for emails' do
        cf = ContactFilter.new(contact_info_email: 'Yes')
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to eq [has_email]
      end

      it 'filters when looking for no emails' do
        cf = ContactFilter.new(contact_info_email: 'No')
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to eq [no_email]
      end

      it 'works when combined with newsletter and ordered by name' do
        cf = ContactFilter.new(contact_info_email: 'No', newsletter: 'address')
        expect(cf.filter(Contact.order('name'), account_list).to_a).to eq([])
      end

      it 'works when combined with facebook and status' do
        has_email.update_attribute(:status, 'Partner - Pray')
        has_email.primary_or_first_person.facebook_accounts << create(:facebook_account)
        another_contact = create(:contact, status: 'Contact for Appointment')
        p = create(:person)
        p.email_addresses << create(:email_address)
        p.facebook_accounts << create(:facebook_account)
        another_contact.people << p
        cf = ContactFilter.new(contact_info_email: 'Yes', contact_info_facebook: 'Yes', status: ['Contact for Appointment'])
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to eq [another_contact]
      end
    end

    context '#contact_info_phone' do
      let!(:has_home) do
        c = create(:contact)
        c.people << create(:person)
        c.people << create(:person)
        c.primary_or_first_person.phone_numbers << create(:phone_number, location: 'home')
        c
      end
      let!(:has_mobile) do
        c = create(:contact)
        c.people << create(:person)
        c.primary_or_first_person.phone_numbers << create(:phone_number, location: 'mobile')
        c
      end
      let!(:has_both) do
        c = create(:contact)
        c.people << home_person = create(:person)
        home_person.phone_numbers << create(:phone_number, location: 'home')
        c.people << mobile_person = create(:person)
        mobile_person.phone_numbers << create(:phone_number, location: 'mobile')
        c
      end
      let!(:no_phone) do
        c = create(:contact)
        c.people << create(:person)
        c.primary_or_first_person.phone_numbers << create(:phone_number, historic: true)
        c
      end

      it 'filters when looking for home phone' do
        cf = ContactFilter.new(contact_info_phone: 'Yes')
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to include has_home
        expect(filtered_contacts).to_not include has_mobile
        expect(filtered_contacts).to_not include no_phone

        cf = ContactFilter.new(contact_info_phone: 'Yes', contact_info_mobile: 'No')
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to include has_home
        expect(filtered_contacts).to_not include has_mobile
        expect(filtered_contacts).to_not include no_phone
      end

      it 'filters when looking for mobile phone' do
        cf = ContactFilter.new(contact_info_mobile: 'Yes')
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to include has_mobile
        expect(filtered_contacts).to_not include has_home
        expect(filtered_contacts).to_not include no_phone

        cf = ContactFilter.new(contact_info_mobile: 'Yes', contact_info_phone: 'No')
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to include has_mobile
        expect(filtered_contacts).to_not include has_home
        expect(filtered_contacts).to_not include no_phone
      end

      it 'filters when looking for both phones' do
        cf = ContactFilter.new(contact_info_mobile: 'Yes', contact_info_phone: 'Yes')
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to include has_both
        expect(filtered_contacts).to_not include has_home
        expect(filtered_contacts).to_not include has_mobile
        expect(filtered_contacts).to_not include no_phone
      end

      it 'filters when looking for no phones' do
        cf = ContactFilter.new(contact_info_phone: 'No', contact_info_mobile: 'No')
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to_not include has_home
        expect(filtered_contacts).to_not include has_mobile
        expect(filtered_contacts).to include no_phone
      end

      it 'works when combined with newsletter and order by name' do
        cf = ContactFilter.new(contact_info_phone: 'No', newsletter: 'address')
        expect(cf.filter(Contact.order('name'), account_list).to_a).to eq([])
      end
    end

    context '#contact_info_address' do
      let!(:has_address) do
        c = create(:contact)
        c.addresses << create(:address)
        c.addresses << create(:address, historic: true)
        c
      end

      it 'filters by contact address present' do
        no_address = create(:contact)
        historic_address_contact = create(:contact)
        historic_address_contact.addresses << create(:address, historic: true)

        cf = ContactFilter.new(contact_info_addr: 'Yes')
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to include has_address
        expect(filtered_contacts).to_not include no_address
        expect(filtered_contacts).to_not include historic_address_contact

        cf = ContactFilter.new(contact_info_addr: 'No', contact_info_email: 'No')
        no_address_contacts = cf.filter(Contact, account_list)
        expect(no_address_contacts).to_not include has_address
        expect(no_address_contacts).to include no_address
        expect(no_address_contacts).to include historic_address_contact
      end

      it 'works when combined with newsletter and ordered by name' do
        create(:contact).addresses << create(:address)
        cf = ContactFilter.new(contact_info_addr: 'No', newsletter: 'address')
        expect(cf.filter(Contact.order('name'), account_list).to_a).to eq([])
      end

      it 'works when combined with status' do
        has_address.update_attribute(:status, 'Partner - Pray')
        another_contact = create(:contact, status: 'Contact for Appointment')
        another_contact.addresses << create(:address)
        cf = ContactFilter.new(contact_info_addr: 'Yes', status: ['Contact for Appointment'])
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to eq [another_contact]
      end
    end

    context '#contact_info_facebook' do
      let!(:has_fb) do
        c = create(:contact)
        c.people << create(:person)
        c.people << create(:person)
        c.primary_or_first_person.facebook_accounts << create(:facebook_account)
        c
      end
      let!(:no_fb) do
        c = create(:contact)
        c.people << create(:person)
        c
      end

      it 'filters when looking for facebook_account' do
        cf = ContactFilter.new(contact_info_facebook: 'Yes')
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to eq [has_fb]
      end

      it 'filters when looking for no facebook_account' do
        cf = ContactFilter.new(contact_info_facebook: 'No')
        filtered_contacts = cf.filter(Contact, account_list)
        expect(filtered_contacts).to include no_fb
        expect(filtered_contacts).to_not include has_fb
      end
    end

    it 'includes contacts with no email when set to email newsletter' do
      has_email = create(:contact, send_newsletter: 'Email')
      p = create(:person)
      has_email.people << p
      create(:email_address, person: p)
      no_email = create(:contact, send_newsletter: 'Email')
      cf = ContactFilter.new(newsletter: 'email')

      filtered_contacts = cf.filter(Contact, account_list)
      expect(filtered_contacts).to include no_email
      expect(filtered_contacts).to include has_email
    end

    it 'includes contacts no currency if account default currency is selected' do
      no_currency_contact = create(:contact, pledge_currency: nil)
      cf = ContactFilter.new(pledge_currency: 'USD')

      filtered_contacts = cf.filter(Contact, account_list)
      expect(filtered_contacts).to include no_currency_contact
    end

    it 'filters when looking for EUR contacts' do
      no_currency_contact = create(:contact, pledge_currency: nil)
      eur_contact = create(:contact, pledge_currency: 'EUR')
      cf = ContactFilter.new(pledge_currency: 'EUR')

      filtered_contacts = cf.filter(Contact, account_list)
      expect(filtered_contacts).to include eur_contact
      expect(filtered_contacts).not_to include no_currency_contact
    end

    it 'filters based on tag' do
      contact1 = create(:contact, tag_list: 'asdf')
      contact2 = create(:contact)
      contact2.donor_accounts << create(:donor_account, master_company: create(:master_company))
      cf = ContactFilter.new(tags: 'asdf')

      expect(cf.filter(Contact.all, build_stubbed(:account_list)))
        .to contain_exactly(contact1)
    end

    it "doesn't display entries when filtering by Newsletter Recipients With Mailing Address" do
      contact = create(:contact, send_newsletter: 'Physical')
      create(:contact)
      2.times do
        contact.addresses << create(:address, addressable: contact)
      end
      cf = ContactFilter.new(newsletter: 'address')

      filtered = cf.filter(Contact.all, build_stubbed(:account_list))

      expect(filtered.length).to be 1
      expect(filtered).to match_array [contact]
    end

    it "doesn't display entries when filtering by Newsletter Recipients With Email Address" do
      contact = create(:contact, send_newsletter: 'Email')
      create(:contact, send_newsletter: 'Physical')
      p = create(:person)
      contact.people << p
      2.times do
        create(:email_address, person: p)
      end
      cf = ContactFilter.new(newsletter: 'email')

      filtered = cf.filter(Contact.all, build_stubbed(:account_list))

      expect(filtered.length).to be 1
      expect(filtered).to match_array [contact]
    end
  end

  context '#locale' do
    it 'filters contacts with locale null and another' do
      contact1 = create(:contact, locale: nil)
      contact2 = create(:contact, locale: 'es')
      create(:contact, locale: 'fr')
      cf = ContactFilter.new(locale: %w(null es))

      expect(cf.filter(Contact, build_stubbed(:account_list)))
        .to contain_exactly(contact1, contact2)
    end

    it 'does not filter out if contacts if locale filter blank' do
      contact1 = create(:contact, locale: 'fr')
      cf = ContactFilter.new(locale: [''])

      expect(cf.filter(Contact, build_stubbed(:account_list)))
        .to contain_exactly(contact1)
    end

    it 'filters only for nil locales if only null given' do
      contact1 = create(:contact, locale: nil)
      create(:contact, locale: 'es')
      cf = ContactFilter.new(locale: ['null'])

      expect(cf.filter(Contact, build_stubbed(:account_list)))
        .to contain_exactly(contact1)
    end

    it 'filters for contacts with specified locales' do
      contact1 = create(:contact, locale: 'de')
      contact2 = create(:contact, locale: 'es')
      create(:contact, locale: 'fr')
      cf = ContactFilter.new(locale: %w(es de))

      expect(cf.filter(Contact, build_stubbed(:account_list)))
        .to contain_exactly(contact1, contact2)
    end

    context '#contact_type' do
      it 'includes both when not filtered' do
        contact1 = create(:contact)
        contact2 = create(:contact)
        contact2.donor_accounts << create(:donor_account, master_company: create(:master_company))
        cf = ContactFilter.new

        expect(cf.filter(Contact.all, build_stubbed(:account_list)))
          .to contain_exactly(contact1, contact2)
      end

      it 'filters out companies' do
        contact1 = create(:contact)
        contact2 = create(:contact)
        contact2.donor_accounts << create(:donor_account, master_company: create(:master_company))
        cf = ContactFilter.new(contact_type: 'person')

        expect(cf.filter(Contact.all, build_stubbed(:account_list)))
          .to contain_exactly(contact1)
      end

      it 'filters out people' do
        create(:contact)
        contact2 = create(:contact)
        contact2.donor_accounts << create(:donor_account, master_company: create(:master_company))
        cf = ContactFilter.new(contact_type: 'company')

        expect(cf.filter(Contact.all, build_stubbed(:account_list)))
          .to contain_exactly(contact2)
      end
    end
  end
end
