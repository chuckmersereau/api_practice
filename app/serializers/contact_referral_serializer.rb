class ContactReferralSerializer < ApplicationSerializer
  belongs_to :referred_by, serializer: ContactSerializer
  belongs_to :referred_to, serializer: ContactSerializer
end
