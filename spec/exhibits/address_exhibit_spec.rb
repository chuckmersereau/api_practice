require 'spec_helper'

describe AddressExhibit do
  let(:context) { double }

  context '.applicable_to?' do
    it 'applies only to Address and not other stuff' do
      expect(AddressExhibit.applicable_to?(Address.new)).to be true
      expect(AddressExhibit.applicable_to?(Contact.new)).to be false
    end
  end

  context '#to_s and #to_google' do
    it 'renders the address in one line' do
      expect_address_single_line_string(:to_s)
      expect_address_single_line_string(:to_google)
    end

    def expect_address_single_line_string(method)
      address = build_stubbed(:address)
      exhibit_context = double
      exhibit = AddressExhibit.new(address, exhibit_context)
      expect(exhibit.public_send(method))
        .to eq '123 Somewhere St, Fremont, CA, 94539, United States'
    end
  end

  context '#to_html' do
    it 'renders US address as two lines without country specified' do
      exhibit = AddressExhibit.new(build_stubbed(:address), double)
      expect(exhibit.to_html)
        .to eq '123 Somewhere St<br />Fremont, CA 94539'
    end

    it 'renders non-US addresses as a single line' do
      exhibit = AddressExhibit.new(build_stubbed(:address, country: 'Canada'), double)
      expect(exhibit.to_html)
        .to eq '123 Somewhere St, Fremont, CA, 94539, Canada'
    end
  end

  context '#to_i18n_html' do
    it 'renders US address without country' do
      exhibit = AddressExhibit.new(build_stubbed(:address), double)
      expect(exhibit.to_i18n_html).to_not include 'United States'
    end

    it 'renders non-US address with country' do
      exhibit = AddressExhibit.new(build_stubbed(:address, country: 'Canada'), double)
      expect(exhibit.to_i18n_html).to include 'Canada'
    end

    it 'renders non-US home address without country' do
      user = create(:user_with_account)
      user.account_lists.first.update(home_country: 'Canada')
      contact = build_stubbed(:contact, account_list: user.account_lists.first)
      address = build_stubbed(:address, country: 'Canada', addressable: contact)
      exhibit = AddressExhibit.new(address, double)
      expect(exhibit.to_i18n_html).to_not include 'Canada'
    end

    it 'renders country specific order' do
      address = build_stubbed(:address, country: 'Germany')
      exhibit = AddressExhibit.new(address, double)
      expect(exhibit.to_i18n_html).to_not include address.state
    end

    it "doesn't error when nil country" do
      address = build_stubbed(:address, country: nil)
      exhibit = AddressExhibit.new(address, double)
      expect(exhibit.to_i18n_html).to include address.state
    end
  end

  context '#address_change_email_body' do
    it 'gives a form email to donor services to request address change' do
      exhibit = AddressExhibit.new(build_stubbed(:address), double)

      expected_email_body =
        "Dear Donation Services,\n\n"\
        "One of my donors, \"Doe, John\" has a new current address.\n\n"\
        "Please update their address to:\n\n"\
        "REPLACE WITH NEW STREET\nREPLACE WITH NEW CITY, STATE, ZIP\n\n"\
        "Thanks!\n\n"

      expect(exhibit.address_change_email_body).to eq expected_email_body
    end
  end
end
