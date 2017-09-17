require 'rails_helper'

RSpec.describe AppealContact, type: :model do
  subject { create(:appeal_contact) }
  it { is_expected.to belong_to(:appeal) }
  it { is_expected.to belong_to(:contact) }
  it { is_expected.to validate_presence_of(:appeal) }
  it { is_expected.to validate_presence_of(:contact) }
  it { is_expected.to validate_uniqueness_of(:contact_id).scoped_to(:appeal_id) }

  describe '#destroy_related_excluded_appeal_contact' do
    let(:account_list) { create(:account_list) }
    let(:appeal) { create(:appeal, account_list: account_list) }
    let(:contact) { create(:contact, account_list: account_list) }
    subject { create(:appeal_contact, appeal: appeal, contact: contact) }

    it 'destroys related excluded appeal contact' do
      create(:appeal_excluded_appeal_contact, appeal: appeal, contact: contact)
      expect do
        subject.destroy_related_excluded_appeal_contact
      end.to change { Appeal::ExcludedAppealContact.count }.from(1).to(0)
    end

    it 'returns true' do
      expect(subject.destroy_related_excluded_appeal_contact).to eq true
    end
  end

  describe 'account list for appeal is not the same as contact' do
    let(:account_list) { create(:account_list) }
    let(:appeal) { create(:appeal, account_list: account_list) }
    let(:contact) { create(:contact) }
    subject { build(:appeal_contact, appeal: appeal, contact: contact) }

    it 'validates contact has same account list as appeal' do
      expect(subject).to_not be_valid
      expect(subject.errors[:contact]).to eq(['does not have the same account list as appeal'])
    end
  end
end
