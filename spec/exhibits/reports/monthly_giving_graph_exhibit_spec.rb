require 'spec_helper'

describe Reports::MonthlyGivingGraphExhibit do
  subject { Reports::MonthlyGivingGraphExhibit.new(report, context) }
  let(:report) { Reports::MonthlyGivingGraph.new(account_list: account_list) }
  let(:account_list) { create :account_list, salary_currency: 'EUR' }
  let(:context) { double }

  context '#salary_currency_symbol' do
    it { expect(subject.salary_currency_symbol).to eq '€' }
  end
end
