require 'rails_helper'

RSpec.describe Contact::Filter::DonationAmountRecommendation do
  subject { described_class.new }

  describe '#execute_query' do
    let(:organization) { create(:organization) }
    let(:designation_account) { create(:designation_account, organization: organization) }
    let!(:account_list) { create(:account_list, designation_accounts: [designation_account]) }
    let(:contacts) { account_list.contacts }
    let(:donor_account1) { create(:donor_account, organization: organization, account_number: '123') }
    let(:donor_account2) { create(:donor_account, organization: organization, account_number: '456') }
    let(:donor_account3) { create(:donor_account, organization: organization, account_number: '789') }
    let!(:contact1) do
      create(
        :contact,
        account_list: account_list,
        pledge_amount: 10,
        pledge_frequency: 1,
        donor_accounts: [donor_account1]
      )
    end
    let!(:contact2) do
      create(
        :contact,
        account_list: account_list,
        pledge_amount: 10,
        pledge_frequency: 1,
        donor_accounts: [donor_account2]
      )
    end
    let!(:contact3) do
      create(
        :contact,
        account_list: account_list,
        pledge_amount: 20,
        pledge_frequency: 1,
        donor_accounts: [donor_account3]
      )
    end
    let!(:contact4) { create(:contact, account_list: account_list) }
    let!(:donation_amount_recommendation1) do
      create(
        :donation_amount_recommendation,
        suggested_pledge_amount: 20,
        donor_account: donor_account1,
        designation_account: designation_account
      )
    end
    let!(:donation_amount_recommendation2) do
      create(
        :donation_amount_recommendation,
        suggested_pledge_amount: 20,
        donor_account: donor_account2,
        designation_account: designation_account
      )
    end
    let!(:donation_amount_recommendation3) do
      create(
        :donation_amount_recommendation,
        suggested_pledge_amount: 20,
        donor_account: donor_account3,
        designation_account: designation_account
      )
    end

    context 'filter is Yes' do
      it 'should return contacts with recommendations' do
        expect(subject.execute_query(contacts, donation_amount_recommendation: 'Yes')).to match_array(
          [contact1, contact2]
        )
      end
    end
    context 'filter is No' do
      it 'should return contacts without recommendations' do
        expect(subject.execute_query(contacts, donation_amount_recommendation: 'No')).to match_array(
          [contact3, contact4]
        )
      end
    end
  end

  describe '#title' do
    it 'should return "Increase Gift Recommendation"' do
      expect(subject.title).to eq 'Increase Gift Recommendation'
    end
  end

  describe '#parent' do
    it 'should return "Gift Details"' do
      expect(subject.parent).to eq 'Gift Details'
    end
  end

  describe '#type' do
    it 'should return "radio"' do
      expect(subject.type).to eq 'radio'
    end
  end

  describe '#custom_options' do
    it 'should return array of options' do
      expect(subject.custom_options).to eq(
        [{ name: _('Yes'), id: 'Yes' }, { name: _('No'), id: 'No' }]
      )
    end
  end
end
