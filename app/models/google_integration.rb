require 'google/apis/calendar_v3'

class GoogleIntegration < ApplicationRecord
  belongs_to :google_account, class_name: 'Person::GoogleAccount', inverse_of: :google_integrations
  belongs_to :account_list, inverse_of: :google_integrations

  serialize :calendar_integrations, Array

  before_save :toggle_calendar_integration_for_appointments, :set_default_calendar, if: :calendar_integration_changed?
  after_save :toggle_email_integration, if: :email_integration_changed?

  delegate :sync_task, to: :calendar_integrator

  validates :calendar_integrations, class: { is_a: Array }

  PERMITTED_ATTRIBUTES = [
    :account_list_id,
    :calendar_integration,
    { calendar_integrations: [] },
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
    @calendar_integrator ||= GoogleCalendarIntegrator.new(self, calendar_service)
  end

  def email_integrator
    @email_integrator ||= GoogleEmailIntegrator.new(self)
  end

  def contacts_integrator
    @contacts_integrator ||= GoogleContactsIntegrator.new(self)
  end

  def calendars
    return @calendars if @calendars

    calendar_list_entries = calendar_service&.list_calendar_lists&.items || []
    @calendars = calendar_list_entries.select do |calendar_list_entry|
      calendar_list_entry.access_role == 'owner'
    end
  end

  private

  def calendar_service
    return unless google_account.authorization

    @calendar_service ||= Google::Apis::CalendarV3::CalendarService.new.tap do |calendar_service|
      calendar_service.authorization = google_account.authorization
    end
  end

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
    self.calendar_id = calendar.id
    self.calendar_name = calendar.summary
  end

  def toggle_email_integration
    queue_sync_data('email') if email_integration?
  end
end
