class GoogleIntegration < ApplicationRecord
  belongs_to :google_account, class_name: 'Person::GoogleAccount', inverse_of: :google_integrations
  belongs_to :account_list, inverse_of: :google_integrations

  attr_accessor :new_calendar

  serialize :calendar_integrations, Array

  before_save :create_new_calendar, if: -> { new_calendar.present? }
  before_save :toggle_calendar_integration_for_appointments, :set_default_calendar, if: :calendar_integration_changed?
  after_save :toggle_email_integration, if: :email_integration_changed?

  delegate :sync_task, to: :calendar_integrator

  PERMITTED_ATTRIBUTES = [
    :account_list_id,
    :calendar_integration,
    :calendar_integrations,
    :calendar_id,
    :calendar_name,
    :email_integration,
    :contacts_integration,
    :overwrite,
    :updated_in_db_at,
    :uuid
  ].freeze

  PERMITTED_INTEGRATIONS = %w(calendar email contacts).freeze

  def queue_sync_data(integration)
    validate_integration!(integration)
    raise 'Cannot queue sync on an unpersisted record!' unless persisted?
    GoogleSyncDataWorker.perform_async(id, integration)
  end

  def sync_data(integration)
    validate_integration!(integration)
    send("#{integration}_integrator").sync_data
  end

  def calendar_integrator
    @calendar_integrator ||= GoogleCalendarIntegrator.new(self)
  end

  def email_integrator
    @email_integrator ||= GoogleEmailIntegrator.new(self)
  end

  def contacts_integrator
    @contacts_integrator ||= GoogleContactsIntegrator.new(self)
  end

  def calendar_api
    client = google_account.client
    @calendar_api ||= client.discovered_api('calendar', 'v3') if client
  end

  def calendars
    return @calendars if @calendars

    @calendars = nil
    api = calendar_api
    if api
      result = google_account.client.execute(
        api_method: api.calendar_list.list,
        parameters: { 'userId' => 'me' }
      )
      calendar_list = result.data
      @calendars = calendar_list.items.select { |c| c.accessRole == 'owner' }
    end

    @calendars || []
  end

  private

  def validate_integration!(integration)
    raise "Invalid integration '#{integration}'!" unless PERMITTED_INTEGRATIONS.include?(integration)
  end

  def toggle_calendar_integration_for_appointments
    if calendar_integration?
      self.calendar_integrations = ['Appointment'] if calendar_integrations.blank?
    else
      self.calendar_integrations = []
    end
  end

  def set_default_calendar
    return unless calendar_integration? && calendar_id.blank? && calendars.length == 1

    calendar = calendars.first
    self.calendar_id = calendar['id']
    self.calendar_name = calendar['summary']
  end

  def create_new_calendar
    result = google_account.client.execute(
      api_method: calendar_api.calendars.insert,
      body_object: { 'summary' => new_calendar }
    )
    self.calendar_id = result.data['id']
    self.calendar_name = new_calendar
  end

  def toggle_email_integration
    queue_sync_data('email') if email_integration?
  end
end
