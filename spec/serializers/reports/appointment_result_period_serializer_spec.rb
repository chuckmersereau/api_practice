require 'rails_helper'

describe Reports::AppointmentResultsPeriodSerializer do
  let(:account_list) { create(:account_list) }
  let(:object) do
    Reports::AppointmentResultsPeriod.new(account_list: account_list,
                                          start_date: 1.week.ago,
                                          end_date: DateTime.current)
  end

  subject { Reports::AppointmentResultsPeriodSerializer.new(object).as_json }

  it 'serializes attributes' do
    expect(subject.keys).to match_array [:start_date,
                                         :end_date,
                                         :individual_appointments,
                                         :weekly_individual_appointment_goal,
                                         :group_appointments,
                                         :new_monthly_partners,
                                         :new_special_pledges,
                                         :monthly_increase,
                                         :pledge_increase,
                                         :created_at,
                                         :id,
                                         :updated_at,
                                         :updated_in_db_at,
                                         :pledge_increase_contacts,
                                         :new_pledges]
  end
end
