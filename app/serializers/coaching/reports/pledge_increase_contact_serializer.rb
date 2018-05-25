class Coaching::Reports::PledgeIncreaseContactSerializer < Reports::PledgeIncreaseContactSerializer
  belongs_to :contact, serializer: Coaching::ContactSerializer
end
