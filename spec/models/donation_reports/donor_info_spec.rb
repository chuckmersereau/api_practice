require 'spec_helper'

describe DonationReports::DonorInfo do
  let(:account_list) { create(:account_list) }
  let(:contact) { create(:contact) }

  describe '.from_contact' do
    it 'intantiates an object with attributes' do
      donor_info = DonationReports::DonorInfo.from_contact(contact)
      expect(donor_info.contact_name).to eq(contact.name)
    end
  end
end
