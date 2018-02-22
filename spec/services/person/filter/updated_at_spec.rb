require 'rails_helper'

RSpec.describe Person::Filter::UpdatedAt do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two) { create(:contact, account_list_id: account_list.id) }

  let!(:person_one)   { create(:person, contacts: [contact_one], updated_at: 2.months.ago) }
  let!(:person_two)   { create(:person, contacts: [contact_one], updated_at: 5.days.ago) }
  let!(:person_three) { create(:person, contacts: [contact_two], updated_at: 2.days.ago) }
  let!(:person_four)  { create(:person, contacts: [contact_two], updated_at: Time.now) }

  describe '#query' do
    let(:scope) { Person.all }

    context 'filter by updated_at range' do
      it 'returns only people that haveupdated_at value within the range' do
        expect(described_class.query(scope, { updated_at: Range.new(1.month.ago, 1.day.ago) }, nil).to_a).to match_array [person_two, person_three]
      end
    end
  end
end
