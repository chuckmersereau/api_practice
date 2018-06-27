require 'rails_helper'

RSpec.describe AppealContact, type: :model do
  subject { create(:appeal_contact) }
  it { is_expected.to belong_to(:appeal) }
  it { is_expected.to belong_to(:contact) }
  it { is_expected.to validate_presence_of(:appeal) }
  it { is_expected.to validate_presence_of(:contact) }
  it { is_expected.to validate_uniqueness_of(:contact_id).scoped_to(:appeal_id).case_insensitive }

  describe 'destroy_related_excluded_appeal_contact' do
    let(:account_list) { create(:account_list) }
    let(:appeal) { create(:appeal, account_list: account_list) }
    let(:contact) { create(:contact, account_list: account_list) }
    let(:contact_two) { create(:contact, account_list: account_list) }
    subject { create(:appeal_contact, appeal: appeal, contact: contact) }

    let(:appeal_contact_force) do
      create(:appeal_contact, appeal: appeal, contact: contact, force_list_deletion: true)
    end

    it 'should not destroy related excluded appeal contact' do
      create(:appeal_excluded_appeal_contact, appeal: appeal, contact: contact)
      expect do
        subject.destroy_related_excluded_appeal_contact
      end.to raise_error.with_message(/Contact is on the Excluded List/)
    end

    it 'should remove the contact from the exclusion list' do
      create(:appeal_excluded_appeal_contact, appeal: appeal, contact: contact)
      expect do
        appeal_contact_force.send(:remove_from_exclusion_list)
      end.to change { Appeal::ExcludedAppealContact.count }
    end

    it 'should be on the exclusion list' do
      contact = create(:appeal_contact, appeal: appeal, contact: contact_two)
      create(:appeal_excluded_appeal_contact, appeal: appeal, contact: contact_two)
      expect(contact.send(:contact_on_exclusion_list?)).to be true
    end

    it 'should not be on the exclusion list' do
      expect(subject.send(:contact_on_exclusion_list?)).to be false
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
