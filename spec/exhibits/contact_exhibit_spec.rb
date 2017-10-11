require 'rails_helper'
describe ContactExhibit do
  let(:exhib) { ContactExhibit.new(contact, context) }
  let(:contact) { build(:contact) }
  let(:context) { double }

  it 'should figure out location based on address' do
    allow(exhib).to receive(:address).and_return(OpenStruct.new(city: 'Rome', state: 'Empire', country: 'Gross'))
    expect(exhib.location).to eq('Rome, Empire, Gross')
  end

  it 'should not have a newsletter error' do
    contact.send_newsletter = _('Physical')
    address = create(:address, addressable: contact)
    contact.addresses << address
    expect(contact.mailing_address).to eq address
    expect(exhib.send_newsletter_error).to be_nil
  end

  it 'should have a newsletter error' do
    contact.send_newsletter = _('Physical')
    expect(contact.mailing_address.equal_to?(Address.new)).to be true
    expect(exhib.send_newsletter_error).to be_present
    contact.send_newsletter = _('Both')
    expect(exhib.send_newsletter_error).to eq('No mailing address or email addess on file')
  end

  context '#avatar' do
    before { allow(context).to receive(:root_url).and_return('https://mpdx.org') }

    it 'ignore images with nil content' do
      person = double(facebook_account: nil,
                      primary_email_address: nil,
                      primary_picture: double(image: double(url: nil)),
                      gender: nil)
      allow(contact).to receive(:primary_person).and_return(person)
      expect(exhib.avatar).to eq('https://mpdx.org/images/avatar.png')
    end

    it 'uses facebook image if remote_id present' do
      person = double(facebook_account: double(remote_id: 1234),
                      primary_picture: double(image: double(url: nil)))
      allow(contact).to receive(:primary_person).and_return(person)
      expect(exhib.avatar).to eq('https://graph.facebook.com/1234/picture?type=square')
    end

    it 'uses google plus avatar if relevant google_account profile_picture_url' do
      google_plus_account = double(profile_picture_link: 'https://google.com/image')
      email_address = double(google_plus_account: google_plus_account)
      person = double(facebook_account: double(remote_id: nil),
                      primary_email_address: email_address,
                      primary_picture: double(image: double(url: nil)))
      allow(contact).to receive(:primary_person).and_return(person)
      expect(exhib.avatar).to eq('https://google.com/image?size=200')
    end

    it 'uses default avatar if facebook remote_id not present' do
      email_address = double(google_plus_account: nil)
      person = double(facebook_account: double(remote_id: nil),
                      primary_picture: double(image: double(url: nil)),
                      primary_email_address: email_address,
                      gender: nil)
      allow(contact).to receive(:primary_person).and_return(person)
      expect(exhib.avatar).to eq('https://mpdx.org/images/avatar.png')
    end
  end

  context '#csv_country' do
    let(:account_list) { build(:account_list, home_country: 'Canada') }
    let(:contact) { build(:contact, addresses: [build(:address)], account_list: account_list) }

    it 'returns the country only if it is different from the account_list home country' do
      expect(ContactExhibit.new(contact, nil).csv_country).to eq(contact.mailing_address.country)
      contact.mailing_address.country = 'Canada'
      expect(ContactExhibit.new(contact, nil).csv_country).to be_blank
    end
  end

  context '#address_block' do
    let(:contact) { build(:contact, addresses: [build(:address)]) }

    it 'returns the greeting and mailing address' do
      expect(ContactExhibit.new(contact, nil).address_block).to eq("#{contact.envelope_greeting}\n123 Somewhere St\nFremont CA  94539")
    end
  end

  # it "should show return the default avatar filename" do
  # contact.gender = 'female'
  # expect(exhib.avatar).to eq('avatar_f.png')
  # contact.gender = 'male'
  # expect(exhib.avatar).to eq('avatar.png')
  # contact.gender = nil
  # expect(exhib.avatar).to eq('avatar.png')
  # end
end
