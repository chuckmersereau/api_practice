require 'rails_helper'

describe Reports::PledgeHistoriesPeriodSerializer do
  let(:account_list) { create(:account_list) }
  let(:object) do
    Reports::PledgeHistoriesPeriod.new(account_list: account_list, start_date: 1.week.ago, end_date: DateTime.now)
  end

  subject { described_class.new(object) }

  it 'serializes attributes' do
    expect(subject.as_json.keys).to match_array [
      :start_date,
      :end_date,
      :pledged,
      :received,
      :created_at,
      :id,
      :updated_at,
      :updated_in_db_at
    ]
  end

  describe '#id' do
    it 'returns a custom id' do
      expect(subject.id).to eq subject.start_date.strftime('%F')
    end
  end
end
