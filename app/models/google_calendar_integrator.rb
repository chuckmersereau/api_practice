class GoogleCalendarIntegrator
  attr_accessor :client

  def initialize(google_integration)
    @google_integration = google_integration
    @google_account = google_integration.google_account
    @client = @google_account.client
  end

  def sync_tasks
    if @google_integration.calendar_integration? && @client
      tasks = @google_integration.account_list.tasks.future.uncompleted.of_type(@google_integration.calendar_integrations)
      tasks.map { |task| sync_task(task.id) }
    end
  end

  def sync_task(task_id)
    return nil unless @google_integration.calendar_integration? && @google_integration.calendar_id

    task = Task.find_by(id: task_id)
    google_event = GoogleEvent.find_by(google_integration_id: @google_integration.id,
                                       calendar_id: @google_integration.calendar_id,
                                       activity_id: task_id)

    if !task || !@google_integration.calendar_integrations.include?(task.activity_type)
      remove_google_event(google_event) if google_event
    elsif google_event
      update_task(task, google_event)
    else
      add_task(task)
    end
  end

  def remove_google_event(google_event)
    result = @client.execute(
      api_method: @google_integration.calendar_api.events.delete,
      parameters: { 'calendarId' => @google_integration.calendar_id,
                    'eventId' => google_event.google_event_id }
    )
    handle_error(result, google_event)
  rescue GoogleCalendarIntegrator::Deleted
    # if the task was already deleted manually, don't worry about it
  ensure
    google_event.destroy
  end

  def update_task(task, google_event)
    result = @client.execute(
      api_method: @google_integration.calendar_api.events.patch,
      parameters: { 'calendarId' => @google_integration.calendar_id,
                    'eventId' => google_event.google_event_id },
      body_object: event_attributes(task)
    )
    handle_error(result, task)
  rescue GoogleCalendarIntegrator::NotFound, GoogleCalendarIntegrator::Deleted
    google_event.destroy
    add_task(task)
  end

  def add_task(task)
    result = @client.execute(
      api_method: @google_integration.calendar_api.events.insert,
      parameters: { 'calendarId' => @google_integration.calendar_id },
      body_object: event_attributes(task)
    )
    handle_error(result, task)
    task.google_events.create!(google_integration_id: @google_integration.id,
                               calendar_id: @google_integration.calendar_id,
                               google_event_id: result.data['id'])
  rescue GoogleCalendarIntegrator::NotFound
    # a NotFound error here means the calendar being referenced doesn't exist on this google account
    @google_integration.update_attributes(
      calendar_id: nil,
      calendar_name: nil,
      calendar_integration: false
    )
  end

  def event_attributes(task)
    attributes = {
      summary: task.subject_with_contacts,
      location: task.location.to_s,
      description: task.activity_comments.map(&:body).join("\n\n"),
      source: { title: 'MPDX', url: 'https://mpdx.org/tasks' }
    }

    if task.default_length
      end_at = task.end_at || task.start_at + task.default_length
      attributes[:start] = { dateTime: task.start_at.to_datetime.rfc3339, date: nil }
      attributes[:end] = { dateTime: end_at.to_datetime.rfc3339, date: nil }
    else
      user = User.find(@google_account.person.id)
      task_date = task.start_at.to_datetime.in_time_zone(user.time_zone).to_date.to_s(:db)
      attributes[:start] = { date: task_date, dateTime: nil }
      attributes[:end] = { date: task_date, dateTime: nil }
    end

    attributes
  end

  def handle_error(result, object)
    case result.status
    when 404
      raise NotFound, result.data.inspect
    when 410
      raise Deleted, result.data.inspect
    else
      return unless result.data && result.data['error'] # no error, everything is fine.
      case result.data['error']['message']
      when 'Invalid attendee email.'
        raise InvalidEmail, event_attributes(object).inspect
      when 'Rate Limit Exceeded', 'Backend Error'
        raise LowerRetryWorker::RetryJobButNoRollbarError
      else
        raise Error, result.data['error']['message'] + " -- #{result.data.inspect}"
      end
    end
  end

  class NotFound < StandardError
  end

  class Deleted < StandardError
  end

  class InvalidEmail < StandardError
  end

  class Error < StandardError
  end
end
