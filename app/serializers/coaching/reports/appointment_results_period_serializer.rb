class Coaching::Reports::AppointmentResultsPeriodSerializer < Reports::AppointmentResultsPeriodSerializer
  has_many :pledge_increase_contacts, serializer: Coaching::Reports::PledgeIncreaseContactSerializer
  has_many :new_pledges, serializer: Coaching::PledgeSerializer
end
