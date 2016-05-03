# encoding: UTF-8
require 'spec_helper'

describe AccountListExhibit do
  subject { AccountListExhibit.new(account_list, context) }
  let(:account_list) { build(:account_list) }
  let(:context) do
    context_double = double(reports_balances_path: '/reports/balances', locale: :en)
    context_double.extend(LocalizationHelper)
    context_double.extend(ActionView::Helpers)
    context_double
  end
  let(:user) { create(:user) }

  context '#to_s' do
    before do
      2.times do
        account_list.designation_accounts << build(:designation_account)
      end
      account_list.users << user
    end

    it 'returns a designation account names for to_s' do
      expect(subject.to_s).to eq(account_list.designation_accounts.map(&:name).join(', '))
    end
  end

  describe 'single currency balances' do
    it 'shows the balance for a single designation' do
      account_list.designation_accounts << create(:designation_account, balance: 5)
      account_list.save
      expect(subject.balances).to include('Balance: $5')
    end

    it 'converts null balances to 0' do
      account_list.designation_accounts << create(:designation_account, balance: nil)
      account_list.save
      expect(subject.balances).to include('Balance: $0')
    end

    it 'sums the balances of designation accounts in the same org' do
      org = create(:fake_org)
      designation1 = create(:designation_account, organization: org, balance: 1)
      designation2 = create(:designation_account, organization: org, balance: 2)
      account_list.designation_accounts << [designation1, designation2]
      account_list.save
      expect(subject.balances).to include('Balance: $3')
    end

    # This case occured during testing for the account list sharing. It may be
    # rare, but we may as well check for it.
    it 'treats and account list entry without a designation account as a blank balance' do
      account_list_entry = create(:account_list_entry, designation_account: nil)
      account_list.account_list_entries << account_list_entry
      account_list.save
      expect(subject.balances).to eq ''
    end

    it 'excludes inactive designations from the total' do
      org = create(:fake_org)
      designation1 = create(:designation_account, organization: org, balance: 1,
                                                  active: false)
      designation2 = create(:designation_account, organization: org, balance: 2)
      account_list.designation_accounts << [designation1, designation2]
      account_list.save
      expect(subject.balances).to include('Balance: $2')
    end
  end

  describe 'multi-currency balances' do
    it 'displays the balance of the salary organization' do
      eur_org = create(:fake_org, default_currency_code: 'EUR')
      gbp_org = create(:fake_org, default_currency_code: 'GBP')
      account_list.update(salary_organization_id: eur_org.id)
      create(:currency_rate, code: 'EUR', exchanged_on: Date.new(2016, 4, 1), rate: 0.88)
      create(:currency_rate, code: 'GBP', exchanged_on: Date.new(2016, 4, 1), rate: 0.69)
      eur_da = create(:designation_account, organization: eur_org, balance: 10)
      gbp_da = create(:designation_account, organization: gbp_org, balance: 20)
      account_list.designation_accounts << [eur_da, gbp_da]

      balances = subject.balances

      expect(balances).to include('Primary Balance: €10')
    end
  end
end
