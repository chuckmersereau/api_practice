module Types
  AccountListType = GraphQL::ObjectType.define do
    name 'AccountList'
    description 'I have no idea. After 3 months of working on this project, I still have no idea what an Account List is.'

    connection :accountListInvites, -> { AccountListInviteType.connection_type }, 'The invites for this Account List', property: :account_list_invites
    connection :appeals, -> { AppealType.connection_type }, 'The Appeals associated with this Account List'
    connection :contacts, -> { ContactConnectionWithAnalyticsAndDuplicatesType }, 'The Contacts associated with this Account List' do
      resolve -> (account_list, args, ctx) {
        ctx[:account_list] = account_list
        account_list.contacts
      }
    end
    connection :tasks, -> { TaskConnectionWithAnalyticsType }, 'The Tasks associated with this Account List' do
      resolve -> (account_list, args, ctx) {
        ctx[:account_list] = account_list
        account_list.tasks
      }
    end
    connection :donations, -> { DonationType.connection_type }, 'The Donations associated with this Account List' do
      resolve -> (account_list, args, ctx) {
        ctx[:account_list_id] = account_list.id
        account_list.donations
      }
    end
    connection :imports, -> { ImportType.connection_type }, 'The Imports associated with this Account List'
    connection :notifications, -> { Types::NotificationType.connection_type }, 'The Notifications associated with this Account List'
    connection :notificationPreferences, -> { NotificationPreferenceType.connection_type }, 'The Notification Preferences for this Account List', property: :notification_preferences

    field :id, !types.ID, 'The UUID of the Account List', property: :uuid
    field :name, !types.String, 'The name of the Account List'
    field :defaultOrganizationId, !types.Int, 'The ID of the default Organization for this Account List'
    field :mailChimpAccount, MailChimpAccountType, 'The Mail Chimp Account for this Account list', property: :mail_chimp_account
    field :monthlyGoal, !types.String, 'The Monthly Goal of the Account List', property: :monthly_goal
    field :totalPledges, !types.Int, 'The total number of pledges', property: :total_pledges
  end
end
