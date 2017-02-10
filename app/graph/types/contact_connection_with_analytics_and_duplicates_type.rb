module Types
  ContactConnectionWithAnalyticsAndDuplicatesType = ContactType.define_connection do
    name 'ContactConnectionWithAnalyticsAndDuplicates'

    field :analytics, !ContactAnalyticsType, 'Analytics on this set of Contacts' do
      resolve -> (obj, args, ctx) {
        Contact::Analytics.new(obj.nodes)
      }
    end

    connection :duplicates, -> { ContactDuplicateType.connection_type }, 'Find Duplicate Contacts on this set of Contacts' do
      resolve -> (obj, args, ctx) {
        return [] unless ctx[:account_list]
        Contact::DuplicatesFinder.new(ctx[:account_list]).find
      }
    end
  end
end
