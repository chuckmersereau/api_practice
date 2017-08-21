module Types
  ContactConnectionWithAnalyticsAndDuplicatesType = ContactType.define_connection do
    name 'ContactConnectionWithAnalyticsAndDuplicates'

    field :analytics, !ContactAnalyticsType, 'Analytics on this set of Contacts' do
      resolve -> (obj, args, ctx) {
        Contact::Analytics.new(obj.nodes)
      }
    end
  end
end
