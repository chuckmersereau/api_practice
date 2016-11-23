class AccountListInviteSerializer < ApplicationSerializer
  attributes :accepted_at,
             :accepted_by_user_id,
             :account_list_id,
             :cancelled_by_user_id,
             :code,
             :invited_by_user_id,
             :recipient_email
end
