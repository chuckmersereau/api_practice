require 'rails_helper'

describe DonationReports::DonationInfoSerializer do
  let(:account_list) { create(:account_list) }
  let(:donation_info) { DonationReports::DonationInfo.from_donation(build(:donation)) }

  subject { DonationReports::DonationInfoSerializer.new(donation_info).as_json }

  it { should include :contact_id }
  it { should include :converted_amount }
  it { should include :converted_currency }
  it { should include :currency }
  it { should include :donation_date }
  it { should include :likelihood_type }

  it 'serializes amount' do
    expect(subject[:amount]).to eq(9.99)
  end

  it 'serializes currency_symbol' do
    expect(subject[:currency_symbol]).to eq('R')
  end

  it 'serializes converted_currency_symbol' do
    expect(subject[:converted_currency_symbol]).to eq(nil)
  end

  context 'converted currency' do
    before do
      account_list.salary_organization_id = create(:organization).id
      DonationReports::DonationsConverter.new(account_list: account_list, donations: [donation_info]).convert_amounts
    end

    it 'serializes converted_currency_symbol' do
      expect(subject[:converted_currency_symbol]).to eq('$')
    end

    it 'serializes converted_amount' do
      expect(subject[:converted_amount]).to eq(9.99)
    end

    it 'serializes converted_currency' do
      expect(subject[:converted_currency]).to eq('USD')
    end
  end
end
