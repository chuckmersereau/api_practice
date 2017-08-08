class GoogleIntegrationSerializer < ApplicationSerializer
  belongs_to :account_list
  belongs_to :google_account
  attributes :calendar_integration,
             :calendar_integrations,
             :calendar_id,
             :calendar_name,
             :email_integration,
             :contacts_integration,
             :calendars

  def calendars
    object.calendars.collect do |calendar_list_entry|
      { id: calendar_list_entry.id, name: calendar_list_entry.summary }
    end
  end
end
