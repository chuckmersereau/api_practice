require 'spec_helper'

describe AddressExhibit do
  subject { ActivityCommentExhibit.new(activity_comment, context) }
  let(:person) { create(:person) }
  let(:activity_comment) { build(:activity_comment, person: person) }
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