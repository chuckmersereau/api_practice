require 'rails_helper'

describe DesignationAccountSerializer do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:designation_account) { create(:designation_account, account_lists: [account_list]) }

  let(:serializer) { DesignationAccountSerializer.new(designation_account, scope: user) }

  it 'balances list' do
    expect(serializer.as_json).to include :balances
    expect(serializer.as_json[:balances][0][:id]).to eq(designation_account.balances[0].id)
  end

  describe '#currency_symbol' do
    it 'returns symbol for designation account currency' do
      expect(designation_account).to receive(:currency).and_return('USD')
      expect(serializer.currency_symbol).to eq('$')
    end
  end

  describe '#converted_balance' do
    it 'returns balance of designation account in salary currency' do
      expect(designation_account).to receive(:converted_balance).with(account_list.salary_currency_or_default)
      expect(serializer.converted_balance).to eq(0.0)
    end
  end

  describe '#total_currency' do
    it 'returns symbol for total currency' do
      expect(serializer.total_currency).to eq(account_list.salary_currency_or_default)
    end
  end

  describe '#exchange_rate' do
    it 'returns exchange rate for currency to total currency' do
      expect(CurrencyRate).to(
        receive(:latest_for_pair).with(from: serializer.currency, to: serializer.total_currency)
          .and_return(0.5)
      )
      expect(serializer.exchange_rate).to eq 0.5
    end
  end

  describe '#active' do
    context 'object active' do
      before { allow(designation_account).to receive(:active).and_return(true) }
      let(:salary_organization_id) { create(:organization).id }
      context 'object organization is salary organization' do
        before do
          account_list.update(salary_organization_id: salary_organization_id)
          designation_account.update(organization_id: salary_organization_id)
        end
        it 'returns true' do
          expect(serializer.active).to be_truthy
        end
      end
      context 'object organization is not salary organization' do
        before do
          account_list.update(salary_organization_id: salary_organization_id)
          designation_account.update(organization_id: create(:organization).id)
        end
        it 'returns false' do
          expect(serializer.active).to be_falsy
        end
      end
    end
    context 'object inactive' do
      before { allow(designation_account).to receive(:active).and_return(false) }
      it 'returns false' do
        expect(serializer.active).to be_falsy
      end
    end
  end

  describe '#display_name' do
    context 'designation_account has name and number' do
      let(:designation_account) { create(:designation_account, name: 'Name', designation_number:  'Number') }
      it 'returns designation_account name (number)' do
        expect(serializer.display_name).to eq 'Name (Number)'
      end
    end
    context 'designation_account has name with number and number' do
      let(:designation_account) { create(:designation_account, name: 'Name Number', designation_number:  'Number') }
      it 'returns designation_account name' do
        expect(serializer.display_name).to eq 'Name Number'
      end
    end
    context 'designation_account has no name' do
      let(:designation_account) { create(:designation_account, name: nil, designation_number: 'Number') }
      it 'returns designation_account number' do
        expect(serializer.display_name).to eq 'Number'
      end
    end
    context 'designation_account has no number' do
      let(:designation_account) { create(:designation_account, name: 'Name', designation_number: nil) }
      it 'returns designation_account name' do
        expect(serializer.display_name).to eq 'Name'
      end
    end
    context 'designation_account has no name and no number' do
      let(:designation_account) { create(:designation_account, name: nil, designation_number: nil) }
      it 'returns designation_account name' do
        expect(serializer.display_name).to eq 'Unknown'
      end
    end
  end
end
