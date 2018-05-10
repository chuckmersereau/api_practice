require 'rails_helper'

describe Reports::AppointmentResultsPeriodSerializer do
  let(:account_list) { create(:account_list) }
  let(:object) { Reports::AppointmentResultsPeriod.new(account_list: account_list, start_date: 1.week.ago, end_date: DateTime.now) }

  subject { Reports::AppointmentResultsPeriodSerializer.new(object).as_json }

  it 'serializes attributes' do
    expect(subject.keys).to match_array [:start_date,
                                         :end_date,
                                         :individual_appointments,
                                         :group_appointments,
                                         :new_monthly_partners,
                                         :new_special_pledges,
                                         :monthly_increase,
                                         :pledge_increase,
                                         :created_at,
                                         :id,
                                         :updated_at,
                                         :updated_in_db_at]
  end
end
