require 'rails_helper'

describe Reports::MonthlyLossesGraphSerializer do
  let(:organization) { create(:organization) }
  let(:account_list) do
    create(:account_list, salary_organization_id: organization)
  end

  let(:report) do
    Reports::MonthlyLossesGraph.new(account_list: account_list, months: 5)
  end

  subject { Reports::MonthlyLossesGraphSerializer.new(report).as_json }

  it { expect(subject[:account_list][:name]).to be account_list.name }
  it { expect(subject[:losses].size).to eq 5 }
  it { expect(subject[:month_names].size).to eq 5 }
end
