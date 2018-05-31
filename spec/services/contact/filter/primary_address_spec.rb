require 'rails_helper'

RSpec.describe Contact::Filter::PrimaryAddress do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  let!(:contact_one)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_two)   { create(:contact, account_list_id: account_list.id) }
  let!(:contact_three) { create(:contact, account_list_id: account_list.id) }
  let!(:contact_four)  { create(:contact, account_list_id: account_list.id) }

  let!(:address_one)   do
    create(:address,
           country: 'United States',
           primary_mailing_address: true,
           addressable: contact_one)
  end

  let!(:address_two) do
    create(:address,
           country: 'United States',
           historic: false,
           addressable: contact_two)
  end

  let!(:address_three) do
    create(:address,
           country: 'United States',
           primary_mailing_address: false,
           addressable: contact_three)
  end

  let!(:address_four) do
    create(:address,
           country: 'United States',
           historic: true,
           addressable: contact_four)
  end

  it 'returns the expected config' do
    options = [{ name: _('Primary'), id: 'primary' },
               { name: _('Active'), id: 'active' },
               { name: _('Inactive'), id: 'inactive' },
               { name: _('All'), id: 'null' }]
    expect(described_class.config([account_list])).to include(name: :primary_address,
                                                              options: options,
                                                              parent: 'Contact Location',
                                                              title: 'Address Type',
                                                              type: 'multiselect',
                                                              default_selection: 'primary, null',
                                                              multiple: true)
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    it 'filters by primary address' do
      result = described_class.query(contacts, { primary_address: 'primary' }, nil).to_a
      expect(result).to include(contact_one)
    end

    it 'filters by active' do
      result = described_class.query(contacts, { primary_address: 'active' }, nil).to_a
      expect(result).to include(contact_two)
    end

    it 'filters by inactive' do
      result = described_class.query(contacts, { primary_address: 'inactive' }, nil).to_a
      expect(result).to include(contact_four)
    end

    it 'filters by all' do
      result = described_class.query(contacts, {}, nil).to_a
      expect(result).to be_empty
    end
  end
end
