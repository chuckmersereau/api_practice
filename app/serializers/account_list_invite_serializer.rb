class AccountListInviteSerializer < BaseSerializer
  attributes :id, :account_list_id, :invited_by_user_id, :code, :recipient_email, :accepted_by_user_id,
             :accepted_at, :cancelled_by_user_id
end
