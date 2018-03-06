require 'rails_helper'

RSpec.describe Contact::Filter::NoAppeals do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  describe '#query' do
    let!(:first_contact) { create(:contact, account_list: account_list, no_appeals: true) }
    let!(:second_contact) { create(:contact, account_list: account_list, no_appeals: nil) }
    let(:contacts) { Contact.all }

    context 'contacts that are marked as no_appeal' do
      it 'returns the correct contacts' do
        expect(described_class.query(contacts, { no_appeals: 'true' }, [account_list])).to eq([first_contact])
      end
    end

    context 'integrated with Contact::Filterer' do
      it 'returns the correct contacts' do
        contacts = Contact::Filterer.new(no_appeals: true)
                                    .filter(scope: account_list.contacts, account_lists: [account_list])

        expect(contacts).to eq [first_contact]
      end
    end
  end
end
