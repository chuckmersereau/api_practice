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
                           salary_organization: org.id
      expect(subject.formatted_balance).to eq '$109'
    end

    it 'accepts an optional locale' do
      account_list.update! designation_accounts: [act_1, act_2, inact_1],
                           salary_organization: org.id
      expect(subject.formatted_balance(locale: :fr)).to eq '109 $'
    end
  end
end
