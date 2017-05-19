require 'rails_helper'

describe DesignationAccount do
  it 'should return designation_number for to_s' do
    expect(DesignationAccount.new(designation_number: 'foo').to_s).to eq('foo')
  end

  it "should return a user's first account list" do
    account_list = double('account_list')
    user = double('user', account_lists: [account_list])
    da = DesignationAccount.new
    allow(da).to receive(:account_lists).and_return([account_list])
    expect(da.account_list(user)).to eq(account_list)
  end

  context '#currency' do
    it 'returns the org default currency code' do
      org = build(:fake_org, default_currency_code: 'GBP')
      designation_account = build(:designation_account, organization: org)

      expect(designation_account.currency).to eq 'GBP'
    end

    it 'returns USD if org has no default currency code' do
      org = build(:fake_org, default_currency_code: nil)
      designation_account = build(:designation_account, organization: org)

      expect(designation_account.currency).to eq 'USD'
    end
  end

  context '#converted_balance' do
    it 'converts balance to specified currency' do
      allow(CurrencyRate).to receive(:convert_with_latest)
        .with(amount: 100.0, from: 'GBP', to: 'EUR') { 124.8 }
      org = build(:fake_org, default_currency_code: 'GBP')
      designation_account = build(:designation_account, organization: org,
                                                        balance: 100.0)

      expect(designation_account.converted_balance('EUR')).to eq 124.8
    end

    it 'returns zero but logs error to rollbar if currency rate missing' do
      allow(Rollbar).to receive(:error)
      allow(CurrencyRate).to receive(:convert_with_latest)
        .and_raise(CurrencyRate::RateNotFoundError)
      org = build(:fake_org, default_currency_code: 'GBP')
      designation_account = build(:designation_account, organization: org,
                                                        balance: 100.0)

      expect(designation_account.converted_balance('EUR')).to eq 0.0
      expect(Rollbar).to have_received(:error)
    end
  end

  describe '.filter' do
    context 'wildcard_search' do
      context 'designation_number starts with' do
        let!(:designation_account) { create(:designation_account, designation_number: '1234') }
        it 'returns designation_account' do
          expect(described_class.filter(wildcard_search: '12')).to eq([designation_account])
        end
      end
      context 'designation_number does not start with' do
        let!(:designation_account) { create(:designation_account, designation_number: '1234') }
        it 'returns no designation_accounts' do
          expect(described_class.filter(wildcard_search: '34')).to be_empty
        end
      end
      context 'name contains' do
        let!(:designation_account) { create(:designation_account, name: 'abcd') }
        it 'returns dnor_account' do
          expect(described_class.filter(wildcard_search: 'bc')).to eq([designation_account])
        end
      end
      context 'name does not contain' do
        let!(:designation_account) { create(:designation_account, name: 'abcd') }
        it 'returns no designation_accounts' do
          expect(described_class.filter(wildcard_search: 'def')).to be_empty
        end
      end
    end
    context 'not wildcard_search' do
      let!(:designation_account) { create(:designation_account, designation_number: '1234') }
      it 'returns designation_account' do
        expect(described_class.filter(designation_number: designation_account.designation_number)).to eq([designation_account])
      end
    end
  end
end
