require 'rails_helper'

RSpec.describe User::Coach do
  subject { create(:user_coach) }
  let(:account_list) { create(:account_list) }
  it { is_expected.to have_many(:coaching_account_lists).through(:account_list_coaches) }

  context '#remove_coach_access' do
    it 'removes coach from account list coaches' do
      account_list.coaches << subject
      subject.remove_coach_access(account_list)
      expect(account_list.reload.coaches).to_not include subject
    end
  end
end
