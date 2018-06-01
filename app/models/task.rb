require 'async'

class Task < Activity
  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :api_task, backtrace: true, unique: :until_executed

  attr_accessor :skip_contact_task_counter_update

  before_validation :update_completed_at
  after_save :update_contact_uncompleted_tasks_count, :queue_sync_to_google_calendar
  after_destroy :update_contact_uncompleted_tasks_count, :queue_sync_to_google_calendar
  after_create :log_newsletter, if: -> { should_log_to_all_contacts? }

  enum notification_type: %w(email mobile both)
  enum notification_time_unit: %w(minutes hours)

  scope :of_type, -> (activity_type) { where(activity_type: activity_type) }
  scope :with_result, -> (result) { where(result: result) }
  scope :completed_between, lambda { |start_date, end_date|
    completed.where('completed_at BETWEEN ? and ?', start_date.in_time_zone, (end_date + 1.day).in_time_zone)
  }
  scope :created_between, lambda { |start_date, end_date|
    where('created_at BETWEEN ? and ?', start_date.in_time_zone, (end_date + 1.day).in_time_zone)
  }
  scope :that_belong_to, -> (user) { where(account_list_id: user.account_list_ids) }

  PERMITTED_ATTRIBUTES = [
    :account_list_id,
    :activity_type,
    :completed,
    :completed_at,
    :created_at,
    :end_at,
    :location,
    :next_action,
    :notification_time_before,
    :notification_time_unit,
    :notification_type,
    :overwrite,
    :result,
    :starred,
    :start_at,
    :subject,
    :tag_list,
    :updated_at,
    :updated_in_db_at,
    :id,
    {
      comment: [
        :body,
        :overwrite
      ],
      comments_attributes: [
        :body,
        :id,
        :_client_id,
        :person_id,
        :overwrite
      ],
      activity_contacts_attributes: [
        :_destroy,
        :id,
        :_client_id,
        :overwrite
      ],
      contacts_attributes: [
        :_destroy,
        :id,
        :_client_id,
        :overwrite
      ]
    }
  ].freeze

  # validates :activity_type, :presence => { :message => _( '/ Action is required') }

  CALL_RESULTS = ['Attempted - Left Message', 'Attempted', 'Completed', 'Received'].freeze
  CALL_NEXT_ACTIONS = [
    'Call',
    'Email',
    'Text Message',
    'Facebook Message',
    'Talk to In Person',
    'Appointment',
    'Prayer Request',
    'Thank'
  ].freeze

  APPOINTMENT_RESULTS = %w(Completed Attempted).freeze
  APPOINTMENT_NEXT_ACTIONS = [
    'Call',
    'Email',
    'Text Message',
    'Facebook Message',
    'Talk to In Person',
    'Appointment',
    'Prayer Request',
    'Thank'
  ].freeze

  EMAIL_RESULTS = %w(Completed Received).freeze
  EMAIL_NEXT_ACTIONS = [
    'Call',
    'Email',
    'Text Message',
    'Facebook Message',
    'Talk to In Person',
    'Appointment',
    'Prayer Request',
    'Thank'
  ].freeze

  FACEBOOK_MESSAGE_RESULTS = %w(Completed Received).freeze
  FACEBOOK_MESSAGE_NEXT_ACTIONS = [
    'Call',
    'Email',
    'Text Message',
    'Facebook Message',
    'Talk to In Person',
    'Appointment',
    'Prayer Request',
    'Thank'
  ].freeze

  TEXT_RESULTS = %w(Completed Received).freeze
  TEXT_NEXT_ACTIONS = [
    'Call',
    'Email',
    'Text Message',
    'Facebook Message',
    'Talk to In Person',
    'Appointment',
    'Prayer Request',
    'Thank'
  ].freeze

  TALK_TO_IN_PERSON_RESULTS = %w(Completed).freeze
  TALK_TO_IN_PERSON_NEXT_ACTIONS = [
    'Call',
    'Email',
    'Text Message',
    'Facebook Message',
    'Talk to In Person',
    'Appointment',
    'Prayer Request',
    'Thank'
  ].freeze

  PRAYER_REQUEST_RESULTS = %w(Completed).freeze
  PRAYER_REQUEST_NEXT_ACTIONS = [
    'Call',
    'Email',
    'Text Message',
    'Facebook Message',
    'Talk to In Person',
    'Appointment',
    'Prayer Request',
    'Thank'
  ].freeze

  LETTER_RESULTS = %w(Completed Received).freeze
  LETTER_NEXT_ACTIONS = [
    'Call',
    'Email',
    'Text Message',
    'Facebook Message',
    'Talk to In Person',
    'None'
  ].freeze

  PRE_CALL_LETTER_RESULTS = LETTER_RESULTS
  PRE_CALL_LETTER_NEXT_ACTIONS = LETTER_NEXT_ACTIONS

  REMINDER_LETTER_RESULTS = LETTER_RESULTS
  REMINDER_LETTER_NEXT_ACTIONS = LETTER_NEXT_ACTIONS

  SUPPORT_LETTER_RESULTS = LETTER_RESULTS
  SUPPORT_LETTER_NEXT_ACTIONS = LETTER_NEXT_ACTIONS

  THANK_RESULTS = LETTER_RESULTS
  THANK_NEXT_ACTIONS = LETTER_NEXT_ACTIONS

  STANDRD_NEXT_ACTIONS = [_('None')].freeze

  MESSAGE_RESULTS = [_('Done'), _('Received')].freeze
  STANDARD_RESULTS = [_('Done')].freeze

  ALL_RESULTS = STANDARD_RESULTS +
                APPOINTMENT_RESULTS +
                CALL_RESULTS +
                MESSAGE_RESULTS +
                TALK_TO_IN_PERSON_RESULTS +
                PRAYER_REQUEST_RESULTS +
                PRE_CALL_LETTER_RESULTS

  TASK_ACTIVITIES = [
    'Call',
    'Appointment',
    'Email',
    'Text Message',
    'Facebook Message',
    'Letter',
    'Newsletter - Physical',
    'Newsletter - Email',
    'Pre Call Letter',
    'Reminder Letter',
    'Support Letter',
    'Thank',
    'To Do',
    'Talk to In Person',
    'Prayer Request'
  ].freeze

  TASK_ACTIVITIES.each do |activity_type|
    singleton_class.instance_eval do
      scope_name = activity_type.parameterize.underscore.to_sym

      define_method scope_name do
        where(activity_type: activity_type)
      end
    end
  end

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
    result == 'Attempted'
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
        next unless person.phone_number&.present?
        "#{person} #{PhoneNumberExhibit.new(person.phone_number, nil)}"
      end
      numbers.compact.join("\n")
    else
      return AddressExhibit.new(contacts.first.address, nil).to_google if contacts.first&.address
    end
  end

  def result_options
    case activity_type
    when 'Call'
      CALL_RESULTS
    when 'Appointment'
      APPOINTMENT_RESULTS
    when 'Email'
      EMAIL_RESULTS
    when 'Facebook Message'
      FACEBOOK_MESSAGE_RESULTS
    when 'Text Message'
      TEXT_RESULTS
    when 'Talk to In Person'
      TALK_TO_IN_PERSON_RESULTS
    when 'Prayer Request'
      PRAYER_REQUEST_RESULTS
    when 'Letter'
      LETTER_RESULTS
    when 'Pre Call Letter'
      PRE_CALL_LETTER_RESULTS
    when 'Reminder Letter'
      REMINDER_LETTER_RESULTS
    when 'Support Letter'
      REMINDER_LETTER_RESULTS
    when 'Thank'
      THANK_RESULTS
    else
      STANDARD_RESULTS
    end
  end

  def next_action_options
    case activity_type
    when 'Call'
      CALL_NEXT_ACTIONS
    when 'Appointment'
      APPOINTMENT_NEXT_ACTIONS
    when 'Email'
      EMAIL_NEXT_ACTIONS
    when 'Facebook Message'
      FACEBOOK_MESSAGE_NEXT_ACTIONS
    when 'Text Message'
      TEXT_NEXT_ACTIONS
    when 'Talk to In Person'
      TALK_TO_IN_PERSON_NEXT_ACTIONS
    when 'Prayer Request'
      PRAYER_REQUEST_NEXT_ACTIONS
    when 'Letter'
      LETTER_NEXT_ACTIONS
    when 'Pre Call Letter'
      PRE_CALL_LETTER_NEXT_ACTIONS
    when 'Reminder Letter'
      REMINDER_LETTER_NEXT_ACTIONS
    when 'Support Letter'
      SUPPORT_LETTER_NEXT_ACTIONS
    when 'Thank'
      THANK_NEXT_ACTIONS
    else
      STANDRD_NEXT_ACTIONS
    end
  end

  def self.all_next_action_options
    options = {}
    options['Call'] = CALL_NEXT_ACTIONS
    options['Appointment'] = APPOINTMENT_NEXT_ACTIONS
    options['Email'] = EMAIL_NEXT_ACTIONS
    options['Facebook Message'] = FACEBOOK_MESSAGE_NEXT_ACTIONS
    options['Text Message'] = TEXT_NEXT_ACTIONS
    options['Talk to In Person'] = TALK_TO_IN_PERSON_NEXT_ACTIONS
    options['Prayer Request'] = PRAYER_REQUEST_NEXT_ACTIONS
    options['Letter'] = LETTER_NEXT_ACTIONS
    options['Pre Call Letter'] = PRE_CALL_LETTER_NEXT_ACTIONS
    options['Reminder Letter'] = REMINDER_LETTER_NEXT_ACTIONS
    options['Support Letter'] = SUPPORT_LETTER_NEXT_ACTIONS
    options['Thank'] = THANK_NEXT_ACTIONS
    options['default'] = STANDRD_NEXT_ACTIONS
    options
  end

  def self.all_result_options
    options = {}
    options['Call'] = CALL_RESULTS
    options['Appointment'] = APPOINTMENT_RESULTS
    options['Email'] = EMAIL_RESULTS
    options['Facebook Message'] = FACEBOOK_MESSAGE_RESULTS
    options['Text Message'] = TEXT_RESULTS
    options['Talk to In Person'] = TALK_TO_IN_PERSON_RESULTS
    options['Letter'] = LETTER_RESULTS
    options['Pre Call Letter'] = PRE_CALL_LETTER_RESULTS
    options['Reminder Letter'] = REMINDER_LETTER_RESULTS
    options['Support Letter'] = SUPPORT_LETTER_RESULTS
    options['Thank'] = THANK_RESULTS
    options['default'] = STANDARD_RESULTS
    options
  end

  def self.alert_frequencies
    {
      '0'      => _('at the time of event'),
      '300'    => _('5 minutes before'),
      '900'    => _('15 minutes before'),
      '1800'   => _('30 minutes before'),
      '3600'   => _('1 hour before'),
      '7200'   => _('2 hours before'),
      '86400'  => _('1 day before'),
      '172800' => _('2 days before'),
      '604800' => _('1 week before')
    }
  end

  def self.mobile_alert_frequencies
    {
      '0'      => _('at the time of event'),
      '300'    => _('5 minutes before'),
      '900'    => _('15 minutes before'),
      '1800'   => _('30 minutes before'),
      '3600'   => _('1 hour before'),
      '7200'   => _('2 hours before'),
      '86400'  => _('1 day before'),
      '172800' => _('2 days before'),
      '604800' => _('1 week before')
    }
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
    contacts.map(&:update_uncompleted_tasks_count) unless skip_contact_task_counter_update
  end

  def queue_sync_to_google_calendar
    return if google_sync_should_not_take_place?

    account_list.google_integrations.each do |google_integration|
      GoogleCalendarSyncTaskWorker.perform_async(google_integration.id, id)
    end
  end

  def google_sync_should_not_take_place?
    result.present? || start_at.nil? || Time.now > start_at
  end

  def log_newsletter
    letter_type = activity_type.sub('Newsletter - ', '')
    contacts_ids = account_list.contacts.where(send_newsletter: [letter_type, 'Both']).ids
    contacts_ids.each do |contact_id|
      task = Task.new(
        account_list: account_list,
        subject: subject,
        activity_type: activity_type,
        completed_at: completed_at,
        completed: completed
      )
      task.activity_contacts.new(contact_id: contact_id, skip_contact_task_counter_update: completed)
      comments.each do |comment|
        task.comments.new(person_id: comment.person_id, body: comment.body)
      end
      task.skip_contact_task_counter_update = completed
      task.save
    end
  end

  def should_log_to_all_contacts?
    (activity_type == 'Newsletter - Physical' || (activity_type == 'Newsletter - Email' && source.nil?)) &&
      contacts.empty?
  end
end
