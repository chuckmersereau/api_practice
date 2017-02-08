require 'rails_helper'

RSpec.describe Reports::Balances, type: :model do
  let!(:user) { create(:user_with_account) }
  let!(:account_list) { user.account_lists.first }
  let!(:balances) { Reports::Balances.new(account_list: account_list) }
  let!(:designation_account) { create(:designation_account) }

  before do
    account_list.designation_accounts << designation_account
  end

  describe 'initializes' do
    it 'initializes successfully' do
      expect(balances).to be_a(Reports::Balances)
      expect(balances.account_list).to eq(account_list)
    end
  end

  describe '#designation_accounts' do
    it 'returns a list of designation accounts' do
      expect(balances.designation_accounts).to be_an ActiveRecord::Relation
      expect(balances.designation_accounts.size).to eq 1
      expect(balances.designation_accounts.first).to be_a DesignationAccount
      expect(balances.designation_accounts.first.uuid).to eq designation_account.uuid
    end
  end

  describe '#total_currency' do
    it { expect(balances.total_currency).to be_a String }
    it { expect(balances.total_currency).to eq account_list.default_currency }
  end

  describe '#total_currency_symbol' do
    it { expect(balances.total_currency_symbol).to be_a String }
    it { expect(balances.total_currency_symbol.size).to eq 1 }
  end
end
