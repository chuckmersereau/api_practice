class GoogleCalendarIntegrator
  def initialize(google_integration)
    @google_integration = google_integration
    @google_account = google_integration.google_account
    @client = @google_account.client
  end

  def sync_tasks
    if @google_integration.calendar_integration?
      tasks = @google_integration.account_list.tasks.future.uncompleted.of_type(@google_integration.calendar_integrations)
      tasks.map { |task| sync_task(task) }
    end
  end

  def sync_task(task)
    return nil unless @google_integration.calendar_id

    google_event = task.google_events.find_by(google_integration_id: @google_integration.id)
    case
    when task.destroyed? && google_event
      remove_task(google_event)
    when google_event
      update_task(task, google_event)
    else
      add_task(task)
    end
  end

  def remove_task(google_event)
    result = @client.execute(
      :api_method => @google_integration.calendar_api.events.delete,
      :parameters => {'calendarId' => @google_integration.calendar_id,
                      'eventId' => google_event.google_event_id}
    )
    handle_error(result)
  end

  def update_task(task, google_event)
    result = @client.execute(
      :api_method => @google_integration.calendar_api.events.patch,
      :parameters => {'calendarId' => @google_integration.calendar_id,
                      'eventId' => google_event.google_event_id},
      :body_object => event_attributes(task)
    )
    Rails.logger.debug(result)
    handle_error(result)
  rescue GoogleCalendarIntegrator::NotFound
    add_task(task)
  end

  def add_task(task)
    result = @client.execute(
      :api_method => @google_integration.calendar_api.events.insert,
      :parameters => {'calendarId' => @google_integration.calendar_id},
      :body_object => event_attributes(task)
    )
    Rails.logger.debug(result)
    handle_error(result)
    task.google_events.create!(google_integration_id: @google_integration.id, google_event_id: result.data['id'])
  end

  def event_attributes(task)
    attributes = {
      summary: task.subject,
      location: task.location.to_s
    }


    if task.default_length
      end_at = task.end_at || task.start_at + task.default_length
      attributes.merge!(start: {dateTime: task.start_at.to_datetime.rfc3339, date: nil},
                        end: {dateTime: end_at.to_datetime.rfc3339, date: nil})
    else
      attributes.merge!(start: {date: task.start_at.to_date.to_s(:db), dateTime: nil},
                        end: {date: task.start_at.to_date.to_s(:db), dateTime: nil})
    end
    Rails.logger.debug(attributes)
    attributes
  end

  def handle_error(result)
    case result.status
    when 404
      raise NotFound
    else
      if result.data['error']
        raise Error, result.data['error']['message']
      end
    end
  end

  class NotFound < StandardError
  end

  class Error < StandardError
  end
end