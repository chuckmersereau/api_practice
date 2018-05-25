class Coaching::PledgeSerializer < ApplicationSerializer
  attributes :amount, :expected_date
  belongs_to :contact, serializer: Coaching::ContactSerializer
end
