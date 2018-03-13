require 'rails_helper'

RSpec.describe Appeal::ExcludedAppealContact, type: :model do
  subject { create(:appeal_excluded_appeal_contact) }
  it { is_expected.to belong_to(:appeal) }
  it { is_expected.to belong_to(:contact) }
  it { is_expected.to validate_presence_of(:appeal) }
  it { is_expected.to validate_presence_of(:contact) }
  it { is_expected.to validate_uniqueness_of(:contact_id).scoped_to(:appeal_id).case_insensitive }

  describe 'account list for appeal is not the same as contact' do
    let(:account_list) { create(:account_list) }
    let(:appeal) { create(:appeal, account_list: account_list) }
    let(:contact) { create(:contact) }
    subject { build(:appeal_excluded_appeal_contact, appeal: appeal, contact: contact) }

    it 'validates contact has same account list as appeal' do
      expect(subject).to_not be_valid
      expect(subject.errors[:contact]).to eq(['does not have the same account list as appeal'])
    end
  end
end
