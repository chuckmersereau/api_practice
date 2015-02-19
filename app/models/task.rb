require 'async'
class Task < Activity
  include Async
  include Sidekiq::Worker
  sidekiq_options backtrace: true, unique: true

  before_validation :update_completed_at
  after_save :update_contact_uncompleted_tasks_count, :sync_to_google_calendar
  after_destroy :update_contact_uncompleted_tasks_count, :sync_to_google_calendar

  scope :of_type, ->(activity_type) { where(activity_type: activity_type) }
  scope :with_result, ->(result) { where(result: result) }
  scope :completed_between, -> (start_date, end_date) { where('completed_at BETWEEN ? and ?', start_date.in_time_zone, (end_date + 1.day).in_time_zone) }
  scope :created_between, -> (start_date, end_date) { where('created_at BETWEEN ? and ?', start_date.in_time_zone, (end_date + 1.day).in_time_zone) }

  PERMITTED_ATTRIBUTES = [
    :starred, :location, :subject, :start_at, :end_at, :activity_type, :result, :completed_at,
    :completed,
    :next_action,
    :tag_list, {
      activity_comments_attributes: [:body],
      activity_comment: [:body],
      activity_contacts_attributes: [:contact_id, :_destroy]
    }
  ]

  # validates :activity_type, :presence => { :message => _( '/ Action is required') }

  CALL_RESULTS = ['Attempted - Left Message', 'Attempted', 'Completed', 'Received']
  CALL_NEXT_ACTIONS = ['Call Again',
                       'Email', 'Text', 'Message',
                       'Appointment Scheduled',
                       'Partner - Financial',
                       'Partner - Special',
                       'Partner - Pray',
                       'Ask in Future',
                       'Not Interested',
                       'None',
                       'Talk to In Person',
                       'Prayer Request']

  APPOINTMENT_RESULTS = %w(Completed Attempted)
  APPOINTMENT_NEXT_ACTIONS = ['Call for Decision',
                              'Call',
                              'Email',
                              'Text',
                              'Message',
                              'Partner - Financial',
                              'Partner - Special',
                              'Partner - Pray',
                              'Ask in Future',
                              'Not Interested',
                              'Reschedule',
                              'None',
                              'Talk to In Person',
                              'Prayer Request']

  EMAIL_RESULTS = %w(Completed Received)
  EMAIL_NEXT_ACTIONS = ['Email Again',
                        'Call', 'Text', 'Message',
                        'Appointment Scheduled',
                        'Partner - Financial',
                        'Partner - Special',
                        'Partner - Pray',
                        'Ask in Future',
                        'Not Interested',
                        'None',
                        'Talk to In Person',
                        'Prayer Request']

  FACEBOOK_MESSAGE_RESULTS = %w(Completed Received)
  FACEBOOK_MESSAGE_NEXT_ACTIONS = ['Message Again',
                                   'Call', 'Email',
                                   'Text',
                                   'Appointment Scheduled',
                                   'Partner - Financial',
                                   'Partner - Special',
                                   'Partner - Pray',
                                   'Ask in Future',
                                   'Not Interested',
                                   'None',
                                   'Talk to In Person',
                                   'Prayer Request']

  TEXT_RESULTS = %w(Completed Received)
  TEXT_NEXT_ACTIONS = ['Text Again',
                       'Call', 'Email', 'Message',
                       'Appointment Scheduled',
                       'Partner - Financial',
                       'Partner - Special',
                       'Partner - Pray',
                       'Ask in Future',
                       'Not Interested',
                       'None',
                       'Talk to In Person',
                       'Prayer Request']

  TALK_TO_IN_PERSON_RESULTS = %w(Completed)
  TALK_TO_IN_PERSON_NEXT_ACTIONS = ['Talk to In Person Again',
                                    'Call', 'Email', 'Message', 'Text',
                                    'Appointment Scheduled',
                                    'Partner - Financial',
                                    'Partner - Special',
                                    'Partner - Pray',
                                    'Ask in Future',
                                    'Not Interested',
                                    'None',
                                    'Prayer Request']

  PRAYER_REQUEST_RESULTS = %w(Completed)
  PRAYER_REQUEST_NEXT_ACTIONS = ['Prayer Request',
                                 'Call', 'Email', 'Message', 'Text',
                                 'Appointment Scheduled',
                                 'Partner - Financial',
                                 'Partner - Special',
                                 'Partner - Pray',
                                 'Ask in Future',
                                 'Not Interested',
                                 'None',
                                 'Talk to In Person']

  MESSAGE_RESULTS = [_('Done'), _('Received')]
  STANDARD_RESULTS = [_('Done')]

  ALL_RESULTS = STANDARD_RESULTS + APPOINTMENT_RESULTS + CALL_RESULTS + MESSAGE_RESULTS + TALK_TO_IN_PERSON_RESULTS + PRAYER_REQUEST_RESULTS

  TASK_ACTIVITIES = ['Call', 'Appointment', 'Email', 'Text Message', 'Facebook Message',
                     'Letter', 'Newsletter', 'Pre Call Letter', 'Reminder Letter',
                     'Support Letter', 'Thank', 'To Do', 'Talk to In Person', 'Prayer Request']

  assignable_values_for :activity_type, allow_blank: true do
    TASK_ACTIVITIES
  end

  # assignable_values_for :result, :allow_blank => true do
  #   case activity_type
  #     when 'Call'
  #       CALL_RESULTS + STANDARD_RESULTS
  #     when 'Email', 'Text Message', 'Facebook Message', 'Letter'
  #       STANDARD_RESULTS + MESSAGE_RESULTS
  #     else
  #       STANDARD_RESULTS
  #   end
  # end

  def attempted?
    'Attempted' == result
  end

  def default_length
    case activity_type
    when 'Appointment'
      1.hour
    when 'Call'
      5.minutes
    end
  end

  def location
    return self[:location] unless self[:location].blank?
    calculated_location
  end

  def calculated_location
    case activity_type
    when 'Call'
      numbers = contacts.map(&:people).flatten.map do |person|
        next unless person.phone_number && person.phone_number.present?
        "#{person} #{PhoneNumberExhibit.new(person.phone_number, nil)}"
      end
      numbers.compact.join("\n")
    else
      return AddressExhibit.new(contacts.first.address, nil).to_google if contacts.first && contacts.first.address
    end
  end

  def result_options
    case activity_type
    when 'Call'
      return CALL_RESULTS
    when 'Appointment'
      return APPOINTMENT_RESULTS
    when 'Email'
      return EMAIL_RESULTS
    when 'Facebook Message'
      return FACEBOOK_MESSAGE_RESULTS
    when 'Text Message'
      return TEXT_RESULTS
    when 'Talk to In Person'
      return TALK_TO_IN_PERSON_RESULTS
    when 'Prayer Request'
      return PRAYER_REQUEST_RESULTS
    else
      return STANDARD_RESULTS
    end
  end

  def next_action_options
    case activity_type
    when 'Call'
      return CALL_NEXT_ACTIONS
    when 'Appointment'
      return APPOINTMENT_NEXT_ACTIONS
    when 'Email'
      return EMAIL_NEXT_ACTIONS
    when 'Facebook Message'
      return FACEBOOK_MESSAGE_NEXT_ACTIONS
    when 'Text Message'
      return TEXT_NEXT_ACTIONS
    when 'Talk to In Person'
      return TALK_TO_IN_PERSON_NEXT_ACTIONS
    when 'Prayer Request'
      return PRAYER_REQUEST_NEXT_ACTIONS
    else
      return ['None']
    end
  end

  private

  def update_completed_at
    return unless changed.include?('completed')
    if completed
      self.completed_at ||= completed? ? Time.now : nil
      self.start_at ||= completed_at
      self.result = 'Done' if result.blank?
    else
      self.completed_at = ''
      self.result = ''
    end
  end

  def update_contact_uncompleted_tasks_count
    contacts.map(&:update_uncompleted_tasks_count)
  end

  def sync_to_google_calendar
    return if result.present? || Time.now > start_at

    account_list.google_integrations.each do |google_integration|
      google_integration.lower_retry_async(:sync_task, id)
    end
  end
end
