class Reports::AppointmentResultsPeriodSerializer < ServiceSerializer
  REPORT_ATTRIBUTES = [:start_date,
                       :end_date,
                       :individual_appointments,
                       :weekly_individual_appointment_goal,
                       :group_appointments,
                       :new_monthly_partners,
                       :new_special_pledges,
                       :monthly_increase,
                       :pledge_increase].freeze
  attributes(*REPORT_ATTRIBUTES)
  delegate(*REPORT_ATTRIBUTES, to: :object)

  has_many :pledge_increase_contacts
  has_many :new_pledges
  delegate(:pledge_increase_contacts, :new_pledges, to: :object)

  def id
    start_date.strftime('%F')
  end
end
