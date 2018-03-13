require 'rails_helper'

RSpec.describe Person::Filter::PhoneNumberValid do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two) { create(:contact, account_list_id: account_list.id) }

  let!(:person_one)   { create(:person, contacts: [contact_one]) }
  let!(:person_two)   { create(:person, contacts: [contact_one]) }
  let!(:person_three) { create(:person, contacts: [contact_two]) }
  let!(:person_four)  { create(:person, contacts: [contact_two]) }

  let!(:phone_number_one) { create(:phone_number, person: person_one) }
  let!(:phone_number_two) { create(:phone_number, person: person_one) }
  let!(:phone_number_three) { create(:phone_number, person: person_one) }
  let!(:phone_number_four) { create(:phone_number, person: person_three) }
  let!(:phone_number_five) { create(:phone_number, person: person_four) }
  let!(:phone_number_six) { create(:phone_number, person: person_two) }

  before do
    phone_number_one.update_columns(valid_values: true, primary: true)
    phone_number_two.update_columns(valid_values: true, primary: true)
    phone_number_three.update_columns(valid_values: true, primary: false)
    phone_number_four.update_columns(valid_values: false, primary: false)
    phone_number_five.update_columns(valid_values: false, primary: false)
    phone_number_six.update_columns(valid_values: true, primary: true)
  end

  describe '#query' do
    let(:scope) { Person.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(scope, {}, nil)).to eq(nil)
        expect(described_class.query(scope, { phone_number_valid: {} }, nil)).to eq(nil)
        expect(described_class.query(scope, { phone_number_valid: [] }, nil)).to eq(nil)
        expect(described_class.query(scope, { phone_number_valid: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by phone number invalid' do
      it 'returns only people that have an invalid phone number' do
        expect(described_class.query(scope, { phone_number_valid: 'false' }, nil).to_a).to match_array [person_one, person_three, person_four]
      end
    end
  end
end
