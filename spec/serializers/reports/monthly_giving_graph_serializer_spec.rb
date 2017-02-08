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

  subject { Reports::MonthlyGivingGraphSerializer.new(report) }

  it { expect(subject.totals).to be_an Array }
  it { expect(subject.monthly_average).to be_a Fixnum }
  it { expect(subject.monthly_goal).to be_a Fixnum }
  it { expect(subject.months_to_dates).to be_an Array }
  it { expect(subject.pledges).to be_a Fixnum }

  it { expect(subject.account_list).to be account_list }
  it { expect(subject.monthly_goal).to eq 1234 }
end
