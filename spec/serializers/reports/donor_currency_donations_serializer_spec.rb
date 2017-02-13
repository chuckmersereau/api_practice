require 'spec_helper'

describe Reports::DonorCurrencyDonationsSerializer do
  let(:organization) { create(:organization) }
  let(:account_list) do
    create(:account_list, monthly_goal: 1234,
                          salary_organization_id: organization)
  end

  let(:report) do
    Reports::DonorCurrencyDonations.new(account_list: account_list)
  end

  subject { Reports::DonorCurrencyDonationsSerializer.new(report).as_json }

  it { should include :account_list }
  it { should include :months }
  it { should include :donor_infos }
  it { should include :currency_groups }
end
