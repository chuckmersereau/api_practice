require 'rails_helper'

RSpec.describe Contact::Filter::PledgeLateBy do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.order(:created_at).first }

  def contact_params(days)
    {
      status: 'Partner - Financial', pledge_frequency: 1,
      account_list_id: account_list.id, pledge_start_date: (1.month + days.days).ago
    }
  end

  let!(:contact_one)   { create(:contact, contact_params(15)) }
  let!(:contact_two)   { create(:contact, contact_params(45)) }
  let!(:contact_three) { create(:contact, contact_params(75)) }
  let!(:contact_four)  { create(:contact, contact_params(105)) }

  describe '#config' do
    it 'returns expected config' do
      expect(described_class.config([account_list])).to include(multiple: false,
                                                                name: :pledge_late_by,
                                                                options: [
                                                                  { name: '-- Any --', id: '', placeholder: 'None' },
                                                                  { name: _('Less than 30 days late'), id: '0_30' },
                                                                  { name: _('More than 30 days late'), id: '30_60' },
                                                                  { name: _('More than 60 days late'), id: '60_90' },
                                                                  { name: _('More than 90 days late'), id: '90' }
                                                                ],
                                                                parent: 'Commitment Details',
                                                                title: 'Late By',
                                                                type: 'radio',
                                                                default_selection: '')
    end
  end

  describe '#query' do
    let(:contacts) { Contact.all }

    context 'no filter params' do
      it 'returns nil' do
        expect(described_class.query(contacts, {}, nil)).to eq(nil)
        expect(described_class.query(contacts, { pledge_late_by: {} }, nil)).to eq(nil)
        expect(described_class.query(contacts, { pledge_late_by: [] }, nil)).to eq(nil)
        expect(described_class.query(contacts, { pledge_late_by: '' }, nil)).to eq(nil)
      end
    end

    context 'filter by days late' do
      it 'returns only contacts that are less than 30 days late' do
        expect(described_class.query(contacts, { pledge_late_by: '0_30' }, nil).to_a).to eq [contact_one]
      end
      it 'returns only contacts that are between 30 to 60 days late' do
        expect(described_class.query(contacts, { pledge_late_by: '30_60' }, nil).to_a).to eq [contact_two]
      end
      it 'returns only contacts that are between 60 to 90 days late' do
        expect(described_class.query(contacts, { pledge_late_by: '60_90' }, nil).to_a).to eq [contact_three]
      end
      it 'returns only contacts that are more than 90 days late' do
        expect(described_class.query(contacts, { pledge_late_by: '90' }, nil).to_a).to eq [contact_four]
      end
    end
  end
end
