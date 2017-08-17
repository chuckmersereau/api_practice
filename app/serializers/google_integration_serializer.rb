class GoogleIntegrationSerializer < ApplicationSerializer
  attributes :calendar_id,
             :calendar_integration,
             :calendar_integrations,
             :calendar_name,
             :calendars,
             :contacts_integration,
             :email_blacklist,
             :email_integration

  belongs_to :account_list
  belongs_to :google_account

  def calendars
    object.calendars.collect do |calendar_list_entry|
      { id: calendar_list_entry.id, name: calendar_list_entry.summary }
    end
  end
end
