require 'rails_helper'

RSpec.describe BalanceSerializer do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:designation_account) { create(:designation_account, account_lists: [account_list]) }
  let(:balance) { create(:balance, resource: designation_account) }
  subject { described_class.new(balance, scope: user).as_json }

  it { expect(subject[:id]).to eq(balance.id) }
  it { expect(subject[:balance]).to eq(balance.balance) }
  it { expect(subject[:resource][:id]).to eq(designation_account.id) }
end
