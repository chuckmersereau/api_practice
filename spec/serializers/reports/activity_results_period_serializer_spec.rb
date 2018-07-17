require 'rails_helper'

describe Reports::ActivityResultsPeriodSerializer do
  let(:account_list) { create(:account_list) }
  let(:object) do
    Reports::ActivityResultsPeriod.new(account_list: account_list,
                                       start_date: 1.week.ago,
                                       end_date: DateTime.current)
  end

  let(:attrs) do
    Reports::ActivityResultsPeriodSerializer::REPORT_ATTRIBUTES + [:created_at, :id, :updated_at, :updated_in_db_at]
  end

  subject { Reports::ActivityResultsPeriodSerializer.new(object).as_json }

  it 'serializes attributes' do
    expect(subject.keys).to match_array attrs
  end
end
