require 'rails_helper'

RSpec.describe DonationImports::Siebel::DonorImporter::PersonImporter do
  let(:mock_siebel_import) { double(:mock_siebel_import) }

  let!(:user) { create(:user_with_account) }
  let(:organization_account) { user.organization_accounts.first }
  let(:organization) { organization_account.organization }

  let(:contact) { create(:contact) }
  let(:donor_account) { create(:donor_account, contacts: [contact]) }

  EmailAddressStructure = Struct.new(:id, :email, :updated_at, :type, :primary)
  PhoneNumberStructure = Struct.new(:id, :phone, :updated_at, :type, :primary)
  PersonStructure = Struct.new(:id, :first_name, :last_name, :primary, :email_addresses,
                               :phone_numbers, :preferred_name, :middle_name, :title, :suffix, :sex)

  let(:first_siebel_email_address) do
    EmailAddressStructure.new('email_id_one', 'email_one@gmail.com')
  end
  let(:second_siebel_email_address) do
    EmailAddressStructure.new('email_id_two', 'email_two@gmail.com', 3.months.ago.to_s)
  end
  let(:siebel_phone_number) { PhoneNumberStructure.new('phone_id_one', '111 222-3333') }
  let(:siebel_person) do
    PersonStructure.new('person_id_one',
                        'Jacob', 'Rudie',
                        true,
                        [first_siebel_email_address, second_siebel_email_address],
                        [siebel_phone_number])
  end

  before do
    allow(mock_siebel_import).to receive(:organization).and_return(organization)
  end

  subject { described_class.new(mock_siebel_import) }

  context '#import_profiles' do
    it 'adds a person and its email and phone number to a contact' do
      expect do
        result = subject.add_or_update_person_on_contact(siebel_person: siebel_person,
                                                         contact: contact,
                                                         donor_account: donor_account,
                                                         date_from: 2.months.ago)
        expect(result).to be_truthy
      end.to change { contact.people.count }.by(1)
        .and change { EmailAddress.count }.by(1)
        .and change { PhoneNumber.count }.by(1)

      expect(contact.primary_person.reload.first_name).to eq('Jacob')
      expect(contact.primary_person.reload.last_name).to eq('Rudie')
      expect(contact.primary_person.email_addresses.pluck(:email).first).to eq('email_one@gmail.com')
      expect(contact.primary_person.phone_numbers.pluck(:number).first).to eq('+1112223333')
    end
  end
end
