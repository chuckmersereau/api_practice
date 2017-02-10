module Types
  ContactAnalyticsType = GraphQL::ObjectType.define do
    name 'ContactAnalytics'
    description "An object of analytics on a User's contacts"

    connection :birthdaysThisWeek, -> { PersonType.connection_type }, 'People who have birthdays this week', property: :birthdays_this_week
    connection :anniversariesThisweek, -> { ContactType.connection_type }, 'Contacts whose anniversary is this week', property: :anniversaries_this_week

    field :createdAt, !types.String, 'The timestamp of when the analytics were generated', resolve: -> (_,_,_) { Time.current }
    field :firstGiftNotReceivedCount, !types.Int, 'Count of contacts that the User has not received their first gift from', property: :first_gift_not_received_count
    field :partners30DaysLateCount, !types.Int, 'Count of contacts who are 30-60 days late on their donation', property: :partners_30_days_late_count
    field :partners60DaysLateCount, !types.Int, 'Count of contacts who are 60+ days late on their donation', property: :partners_60_days_late_count
  end
end
