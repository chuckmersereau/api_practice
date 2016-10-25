require 'spec_helper'
describe ContactExhibit do
  let(:exhib) { ContactExhibit.new(contact, context) }
  let(:contact) { build(:contact) }
  let(:context) { double }

  it 'returns referrers as a list of links' do
    allow(context).to receive(:link_to).and_return('foo')
    allow(exhib).to receive(:referrals_to_me).and_return(%w(foo foo))
    expect(exhib.referrer_links).to eq('foo, foo')
  end

  it 'should figure out location based on address' do
    allow(exhib).to receive(:address).and_return(OpenStruct.new(city: 'Rome', state: 'Empire', country: 'Gross'))
    expect(exhib.location).to eq('Rome, Empire, Gross')
  end

  it 'should show contact_info' do
    allow(context).to receive(:contact_person_path)
    contact = create(:contact)
    person = create(:person)
    contact.people << person

    exhib = ContactExhibit.new(contact, context)
    email = build(:email_address, person: person)
    phone_number = build(:phone_number, person: person)
    allow(context).to receive(:link_to).and_return("#{phone_number.number}<br />#{email.email}")
    expect(exhib.contact_info).to eq("#{phone_number.number}<br />#{email.email}")
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
                      primary_picture: double(image: double(url: nil)),
                      gender: nil)
      allow(contact).to receive(:primary_person).and_return(person)
      expect(exhib.avatar).to eq('https://mpdx.org/assets/avatar.png')
    end

    it 'uses make facebook image if remote_id present' do
      person = double(facebook_account: double(remote_id: 1234),
                      primary_picture: double(image: double(url: nil)))
      allow(contact).to receive(:primary_person).and_return(person)
      expect(exhib.avatar).to eq('https://graph.facebook.com/1234/picture?type=square')
    end

    it 'uses default avatar if facebook remote_id not present' do
      person = double(facebook_account: double(remote_id: nil),
                      primary_picture: double(image: double(url: nil)),
                      gender: nil)
      allow(contact).to receive(:primary_person).and_return(person)
      expect(exhib.avatar).to eq('https://mpdx.org/assets/avatar.png')
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
