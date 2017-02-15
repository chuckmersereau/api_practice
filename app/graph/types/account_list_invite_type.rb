module Types
  AccountListInviteType = GraphQL::ObjectType.define do
    name 'AccountListInvite'
    description 'An Account List Invite object'

    field :id, !types.ID, 'The UUID of the Account List Invite', property: :uuid
    field :acceptedAt, types.String, 'The time that the User accepted the Invitation', property: :accepted_at
    field :acceptedByUser, UserType, 'The User that accepted the Invitation', property: :accepted_by_user
    field :accountList, AccountListType, 'The parent Account List', property: :account_list
    field :cancelledByUser, UserType, 'The User that cancelled the Invitation', property: :cancelled_by_user
    field :code, types.String, 'TODO'
    field :createdAt, types.String, 'The timestamp for when this Invitation was created', property: :created_at
    field :invitedByUser, UserType, 'The User that invited the Recipient', property: :invited_by_user
    field :recipientEmail, !types.String, 'Email Address of the Recipient', property: :recipient_email
    field :updatedAt, types.String, 'The timestamp of the last time this was updated', property: :updated_at
    field :updatedInDbAt, types.String, 'The timestamp of the last time this was updated in the db', property: :updated_at
  end
end
