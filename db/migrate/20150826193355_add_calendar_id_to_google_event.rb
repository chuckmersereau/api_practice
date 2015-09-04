class AddCalendarIdToGoogleEvent < ActiveRecord::Migration
  def change
    add_column :google_events, :calendar_id, :string

    GoogleEvent.connection.execute(
      'UPDATE google_events
       SET calendar_id = google_integrations.calendar_id
       FROM google_integrations
       WHERE google_events.google_integration_id = google_integrations.id'
    )
  end
end
