class AccountListInviteSerializer < ApplicationSerializer
  attributes :accepted_at,
             :code,
             :recipient_email

  belongs_to :accepted_by_user
  belongs_to :cancelled_by_user
  belongs_to :invited_by_user
end
