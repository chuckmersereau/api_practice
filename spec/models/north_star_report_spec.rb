require 'spec_helper'

RSpec.describe NorthStarReport, type: :model do
  describe 'weeks' do
    around do |example|
      travel_to(Date.new(2016, 4, 20)) { example.run }
    end

    before do
      u1 = create(:user_with_account)
      u2 = create(:user_with_account)

      u1.account_lists.first.tasks << create(:task, completed_at: 1.week.ago)
      u1.account_lists.first.tasks << create(:task, completed_at: 2.weeks.ago)
      u2.account_lists.first.tasks << create(:task, completed_at: 1.week.ago)
    end

    it 'loads counts' do
      report = NorthStarReport.new.weeks

      expect(report.length).to be 2
      expect(report.first['week']).to eq '04-04-16'
      expect(report.first['users']).to eq '1'
      expect(report.last['week']).to eq '04-11-16'
      expect(report.last['users']).to eq '2'
    end
  end

  describe 'months' do
    before do
      travel_to Date.new(2016, 4, 20)

      u1 = create(:user_with_account)
      u2 = create(:user_with_account)

      u1.account_lists.first.tasks << create(:task, completed_at: 1.month.ago)
      u1.account_lists.first.tasks << create(:task, completed_at: 2.months.ago)
      u2.account_lists.first.tasks << create(:task, completed_at: 1.month.ago)
    end

    it 'loads counts' do
      report = NorthStarReport.new.months

      expect(report.length).to be 2
      expect(report.first['month']).to eq '02-2016'
      expect(report.first['users']).to eq '1'
      expect(report.last['month']).to eq '03-2016'
      expect(report.last['users']).to eq '2'
    end
  end
end
