# encoding: UTF-8
require 'rails_helper'

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

  context '#weeks_on_mpd' do
    it 'is nil without a start' do
      account_list.update! active_mpd_start_at: nil
      expect(subject.weeks_on_mpd).to be_nil
    end

    it 'is nil without a finish' do
      account_list.update! active_mpd_finish_at: nil
      expect(subject.weeks_on_mpd).to be_nil
    end

    it 'is a number' do
      account_list.update! active_mpd_start_at: 1.week.ago,
                           active_mpd_finish_at: 1.week.from_now
      expect(subject.weeks_on_mpd).to be_a Numeric
    end

    it 'returns the difference in weeks' do
      account_list.update! active_mpd_start_at: 6.weeks.ago,
                           active_mpd_finish_at: 5.weeks.from_now
      expect(subject.weeks_on_mpd).to eq 11
    end

    it 'can return fractions of a week' do
      account_list.update! active_mpd_start_at: 6.weeks.ago,
                           active_mpd_finish_at: 3.days.from_now
      expect(subject.weeks_on_mpd).to eq(6 + 3.0 / 7)
    end
  end

  context '#last_prayer_letter_at' do
    let(:date) { 5.weeks.ago }
    let(:mail_chimp_account) { create(:mail_chimp_account, prayer_letter_last_sent: date) }

    it 'is nil without a #mail_chimp_account' do
      account_list.update! mail_chimp_account: nil
      expect(subject.last_prayer_letter_at).to be_nil
    end

    it 'is a date' do
      account_list.update! mail_chimp_account: mail_chimp_account
      expect(subject.last_prayer_letter_at).to eq date
    end
  end

  context '#formatted_balance' do
    let(:org) { create(:organization) }
    let(:act_1) { create(:designation_account, active: true, balance: 10, organization: org) }
    let(:act_2) { create(:designation_account, active: true, balance: 99, organization: org) }
    let(:inact_1) { create(:designation_account, active: false, balance: 50, organization: org) }

    it 'defaults to $0 with no designation_accounts' do
      account_list.update! designation_accounts: []
      expect(subject.formatted_balance).to eq '$0'
    end

    it "is the sum of each active account's balance" do
      account_list.update! designation_accounts: [act_1, act_2, inact_1],
                           salary_organization: org.uuid
      expect(subject.formatted_balance).to eq '$109'
    end

    it 'accepts an optional locale' do
      account_list.update! designation_accounts: [act_1, act_2, inact_1],
                           salary_organization: org.uuid
      expect(subject.formatted_balance(locale: :fr)).to eq '109 $'
    end
  end
end
