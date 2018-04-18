require 'rails_helper'

RSpec.describe Contact::Filter::DesignationAccountId do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }
  let(:designation_account_1) { create(:designation_account) }
  let(:designation_account_2) { create(:designation_account) }
  before do
    account_list.designation_accounts << designation_account_1
    account_list.designation_accounts << designation_account_2
  end

  describe '#query' do
    let!(:contact_1) do
      donor_account = create(:donor_account, account_number: '1')
      create(:donation, donor_account: donor_account, designation_account: designation_account_1)
      create(
        :contact,
        account_list: account_list,
        donor_accounts: [donor_account]
      )
    end
    let!(:contact_2) do
      donor_account = create(:donor_account, account_number: '2')
      create(:donation, donor_account: donor_account, designation_account: designation_account_2)
      create(
        :contact,
        account_list: account_list,
        donor_accounts: [donor_account]
      )
    end
    let!(:contact_3) do
      donor_account = create(:donor_account, account_number: '3')
      create(:donation, donor_account: donor_account, designation_account: designation_account_1)
      create(:donation, donor_account: donor_account, designation_account: designation_account_2)
      create(
        :contact,
        account_list: account_list,
        donor_accounts: [donor_account]
      )
    end
    let!(:contact_4) { create(:contact, account_list: account_list) }
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { designation_account_id: {} }, nil)).to eq(nil)
      end
    end

    context 'for single designation_account' do
      it 'returns the correct contacts' do
        expect(described_class.query(contacts, { designation_account_id: designation_account_1.id }, nil)).to(
          contain_exactly(contact_1, contact_3)
        )
        expect(described_class.query(contacts, { designation_account_id: designation_account_2.id }, nil)).to(
          contain_exactly(contact_2, contact_3)
        )
      end
    end

    context 'for multiple designation_accounts' do
      it 'returns the correct contacts' do
        expect(
          described_class.query(
            contacts,
            {
              designation_account_id: [designation_account_1.id, designation_account_2.id]
            },
            nil
          )
        ).to(
          contain_exactly(contact_1, contact_2, contact_3)
        )
      end
    end

    context 'with reverse_FILTER' do
      subject { described_class.query(contacts, query, nil) }
      let(:query) { { designation_account_id: designation_account_id, reverse_designation_account_id: true } }

      context 'designation_account_id: designation_account_1' do
        let(:designation_account_id) { designation_account_1.id }
        it 'returns contacts that have not donated to designation_account_1' do
          is_expected.to contain_exactly(contact_2, contact_4)
        end
      end

      context 'designation_account_id: designation_account_1 & designation_account_2' do
        let(:designation_account_id) { [designation_account_1.id, designation_account_2.id] }
        it 'returns contacts that have not donated to designation_account_1 & designation_account_2' do
          is_expected.to contain_exactly(contact_4)
        end
      end
    end
  end

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(
        default_selection: '',
        multiple: true,
        name: :designation_account_id,
        options: [{ name: '-- Any --', id: '', placeholder: 'None' },
                  {
                    name: DesignationAccountSerializer.new(designation_account_1).display_name,
                    id: designation_account_1.id
                  }, {
                    name: DesignationAccountSerializer.new(designation_account_2).display_name,
                    id: designation_account_2.id
                  }],
        parent: 'Gift Details',
        title: 'Designation Acccount',
        type: 'multiselect'
      )
    end
  end
end
