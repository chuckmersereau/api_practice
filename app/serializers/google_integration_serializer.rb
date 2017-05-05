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
    object.calendars.map { |c| { id: c['id'], name: c['summary'] } }
  end
end
