require 'spec_helper'

describe DonationReports::DonorInfoSerializer do
  let(:account_list) { create(:account_list) }
  let(:donor_info) { DonationReports::DonorInfo.from_contact(build(:contact)) }

  subject { DonationReports::DonorInfoSerializer.new(donor_info).as_json }

  it { should include :contact_id }
  it { should include :contact_name }
  it { should include :late_by_30_days }
  it { should include :late_by_60_days }
  it { should include :pledge_currency }

  it 'serializes status' do
    expect(subject[:status]).to eq('Partner - Financial')
  end

  it 'serializes pledge_frequency' do
    expect(subject[:pledge_frequency]).to eq('Monthly')
  end

  it 'serializes pledge_amount' do
    expect(subject[:pledge_amount]).to eq(100.0)
  end
end
