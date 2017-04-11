require 'async'
class GoogleIntegration < ApplicationRecord
  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :api_google_integration, unique: :until_executed

  sidekiq_retry_in do |count|
    count**6 + 30 # 30, 31, 94, 759, 4126 ... second delays
  end

  belongs_to :google_account, class_name: 'Person::GoogleAccount', inverse_of: :google_integrations
  belongs_to :account_list, inverse_of: :google_integrations

  attr_accessor :new_calendar

  serialize :calendar_integrations, Array

  before_save :create_new_calendar, if: -> { new_calendar.present? }
  before_save :toggle_calendar_integration_for_appointments, :set_default_calendar, if: :calendar_integration_changed?
  before_save :toggle_email_integration, if: :email_integration_changed?

  delegate :sync_task, to: :calendar_integrator

  def queue_sync_data(integration = nil)
    return unless integration

    if integration == 'contacts'
      account_list.queue_sync_with_google_contacts
    else
      lower_retry_async(:sync_data, integration)
    end
  end

  def sync_data(integration)
    case integration
    when 'calendar'
      calendar_integrator.sync_tasks
    when 'email'
      sync_email
    when 'contacts'
      contacts_integrator.sync_contacts
    end
  end

  def sync_email
    email_integrator.sync_mail
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

  def plus_api
    @plus_api ||= google_account.client.discovered_api('plus')
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

    @calendars
  end

  def toggle_calendar_integration_for_appointments
    if calendar_integration?
      calendar_integrations << 'Appointment' if calendar_integrations.blank?
    else
      self.calendar_integrations = []
    end
  end

  def set_default_calendar
    return false unless calendars
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

  def self.sync_all_email_accounts
    email_integrations = GoogleIntegration.where(email_integration: true)
    AsyncScheduler.schedule_over_24h(email_integrations, :sync_email, :api_google_integration_sync_email)
  end
end
