require 'rails_helper'

RSpec.describe Person::Filter::EmailAddressValid do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two) { create(:contact, account_list_id: account_list.id) }

  let!(:person_one)   { create(:person, contacts: [contact_one]) }
  let!(:person_two)   { create(:person, contacts: [contact_one]) }
  let!(:person_three) { create(:person, contacts: [contact_two]) }
  let!(:person_four)  { create(:person, contacts: [contact_two]) }

  let!(:email_address_one) { create(:email_address, person: person_one) }
  let!(:email_address_two) { create(:email_address, person: person_one) }
  let!(:email_address_three) { create(:email_address, person: person_one) }
  let!(:email_address_four) { create(:email_address, person: person_three) }
  let!(:email_address_five) { create(:email_address, person: person_four) }
  let!(:email_address_six) { create(:email_address, person: person_two) }

  before do
    email_address_one.update_columns(valid_values: true, primary: true)
    email_address_two.update_columns(valid_values: true, primary: true)
    email_address_three.update_columns(valid_values: true, primary: false)
    email_address_four.update_columns(valid_values: false, primary: false)
    email_address_five.update_columns(valid_values: false, primary: false)
    email_address_six.update_columns(valid_values: true, primary: true)
  end

  describe '#query' do
    let(:scope) { Person.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(scope, {}, nil)).to eq(nil)
        expect(described_class.query(scope, { email_address_valid: {} }, nil)).to eq(nil)
        expect(described_class.query(scope, { email_address_valid: [] }, nil)).to eq(nil)
        expect(described_class.query(scope, { email_address_valid: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by email address invalid' do
      it 'returns only people that have an invalid email address' do
        expect(described_class.query(scope, { email_address_valid: 'false' }, nil).to_a).to match_array [person_one, person_three, person_four]
      end
    end
  end
end
