class GoogleCalendarIntegrator
  attr_accessor :google_integration, :google_account, :calendar_service

  def initialize(google_integration, calendar_service)
    @google_integration = google_integration
    @google_account = google_integration.google_account
    @calendar_service = calendar_service
  end

  def sync_data
    return unless google_integration.calendar_integration? && calendar_service && google_integration.calendar_id

    task_ids = google_integration.account_list.tasks.future.uncompleted.of_type(google_integration.calendar_integrations).ids
    task_ids.map { |task_id| sync_task(task_id) }
  end
  alias sync_tasks sync_data

  def sync_task(task_id)
    return unless google_integration.calendar_integration? && calendar_service && google_integration.calendar_id

    task = Task.find_by(id: task_id)
    google_event = GoogleEvent.find_by(google_integration_id: google_integration.id,
                                       calendar_id: google_integration.calendar_id,
                                       activity_id: task_id)

    if !task || !google_integration.calendar_integrations.include?(task.activity_type)
      remove_google_event(google_event) if google_event
    elsif google_event
      update_task(task, google_event)
    else
      add_task(task)
    end
  end

  private

  def remove_google_event(google_event)
    begin
      calendar_service.delete_event(google_integration.calendar_id,
                                    google_event.google_event_id)
    rescue Google::Apis::ClientError => error
      raise error unless status_code_indicates_event_is_no_longer_available?(error.status_code)
    end

    google_event.destroy
  end

  def update_task(task, google_event)
    calendar_service.patch_event(google_integration.calendar_id,
                                 google_event.google_event_id,
                                 build_api_event_from_mpdx_task(task))
  rescue Google::Apis::ClientError => error
    raise error unless status_code_indicates_event_is_no_longer_available?(error.status_code)
    google_event&.destroy
    add_task(task)
  end

  def add_task(task)
    result_event = calendar_service.insert_event(google_integration.calendar_id,
                                                 build_api_event_from_mpdx_task(task))

    task.google_events.create!(google_integration_id: google_integration.id,
                               calendar_id: google_integration.calendar_id,
                               google_event_id: result_event.id)

  rescue Google::Apis::ClientError => error
    raise error unless error.status_code == 404
    # A 404 error here means the calendar being referenced doesn't exist on this Google account
    google_integration.update_attributes(
      calendar_id: nil,
      calendar_name: nil,
      calendar_integration: false
    )
  end

  def event_summary_for_task(task)
    first_part = [task.contacts.map(&:to_s).join(', '), _(task.activity_type)].select(&:present?).join(' - ')
    [first_part, task.subject].select(&:present?).join(': ')
  end

  def build_api_event_from_mpdx_task(task)
    event = Google::Apis::CalendarV3::Event.new

    event.summary     = event_summary_for_task(task)
    event.location    = task.location&.to_s
    event.description = task.comments.map(&:body).join("\n\n")
    event.source      = Google::Apis::CalendarV3::Event::Source.new(title: 'MPDX', url: 'https://mpdx.org/tasks')

    if task.default_length
      event.start = Google::Apis::CalendarV3::EventDateTime.new(date_time: task.start_at.to_datetime.rfc3339)
      end_at      = task.end_at || task.start_at + task.default_length
      event.end   = Google::Apis::CalendarV3::EventDateTime.new(date_time: end_at.to_datetime.rfc3339)
    else
      time_zone   = google_account.user.time_zone
      task_date   = task.start_at.to_datetime.in_time_zone(time_zone).to_date.to_s(:db)
      event.start = Google::Apis::CalendarV3::EventDateTime.new(date: task_date)
      event.end   = Google::Apis::CalendarV3::EventDateTime.new(date: task_date)
    end

    event
  end

  def status_code_indicates_event_is_no_longer_available?(code)
    [404, 410].include?(code)
  end
end
