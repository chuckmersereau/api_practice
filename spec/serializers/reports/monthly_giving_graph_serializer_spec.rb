require 'rails_helper'

describe Reports::MonthlyGivingGraphSerializer do
  let(:organization) { create(:organization) }
  let(:locale) { 'en' }
  let(:account_list) do
    create(:account_list, monthly_goal: 1234,
                          salary_organization_id: organization)
  end

  let(:report) do
    Reports::MonthlyGivingGraph.new(account_list: account_list,
                                    locale: locale)
  end

  subject { Reports::MonthlyGivingGraphSerializer.new(report).as_json }

  it { expect(subject[:account_list][:name]).to be account_list.name }
  it { expect(subject[:monthly_goal]).to eq 1234 }
end
