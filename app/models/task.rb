require 'async'

class Task < Activity
  include Async
  include Sidekiq::Worker
  sidekiq_options backtrace: true, unique: :until_executed

  before_validation :update_completed_at
  after_save :update_contact_uncompleted_tasks_count, :sync_to_google_calendar
  after_destroy :update_contact_uncompleted_tasks_count, :sync_to_google_calendar

  enum notification_type: %w(email)
  enum notification_time_unit: %w(minutes hours)

  scope :of_type, -> (activity_type) { where(activity_type: activity_type) }
  scope :with_result, -> (result) { where(result: result) }
  scope :completed_between, -> (start_date, end_date) { completed.where('completed_at BETWEEN ? and ?', start_date.in_time_zone, (end_date + 1.day).in_time_zone) }
  scope :created_between, -> (start_date, end_date) { where('created_at BETWEEN ? and ?', start_date.in_time_zone, (end_date + 1.day).in_time_zone) }
  scope :that_belong_to, -> (user) { where(account_list_id: user.account_list_ids) }

  PERMITTED_ATTRIBUTES = [:account_list_id,
                          :activity_type,
                          :completed,
                          :completed_at,
                          :created_at,
                          :location,
                          :next_action,
                          :no_date,
                          :notification_time_before,
                          :notification_time_unit,
                          :notification_type,
                          :result,
                          :starred,
                          :start_at, :end_at,
                          :subject,
                          :tag_list,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid,
                          { activity_comment: [:body],
                            activity_comments_attributes: [:body],
                            activity_contacts_attributes: [:contact_id, :_destroy] }].freeze

  # validates :activity_type, :presence => { :message => _( '/ Action is required') }

  CALL_RESULTS = ['Attempted - Left Message', 'Attempted', 'Completed', 'Received'].freeze
  CALL_NEXT_ACTIONS = ['Call Again',
                       'Email', 'Text', 'Message',
                       'Talk to In Person',
                       'Cultivate Relationship',
                       'Appointment Scheduled',
                       'Partner - Financial',
                       'Partner - Special',
                       'Partner - Pray',
                       'Ask in Future',
                       'Not Interested',
                       'None',
                       'Prayer Request',
                       'Thank'].freeze

  APPOINTMENT_RESULTS = %w(Completed Attempted).freeze
  APPOINTMENT_NEXT_ACTIONS = ['Call for Decision',
                              'Call',
                              'Email',
                              'Text',
                              'Message',
                              'Talk to In Person',
                              'Cultivate Relationship',
                              'Partner - Financial',
                              'Partner - Special',
                              'Partner - Pray',
                              'Ask in Future',
                              'Not Interested',
                              'Reschedule',
                              'None',
                              'Prayer Request',
                              'Thank'].freeze

  EMAIL_RESULTS = %w(Completed Received).freeze
  EMAIL_NEXT_ACTIONS = ['Email Again',
                        'Call', 'Text', 'Message',
                        'Talk to In Person',
                        'Cultivate Relationship',
                        'Appointment Scheduled',
                        'Partner - Financial',
                        'Partner - Special',
                        'Partner - Pray',
                        'Ask in Future',
                        'Not Interested',
                        'None',
                        'Prayer Request',
                        'Thank'].freeze

  FACEBOOK_MESSAGE_RESULTS = %w(Completed Received).freeze
  FACEBOOK_MESSAGE_NEXT_ACTIONS = ['Message Again',
                                   'Call', 'Email',
                                   'Text',
                                   'Talk to In Person',
                                   'Cultivate Relationship',
                                   'Appointment Scheduled',
                                   'Partner - Financial',
                                   'Partner - Special',
                                   'Partner - Pray',
                                   'Ask in Future',
                                   'Not Interested',
                                   'None',
                                   'Prayer Request',
                                   'Thank'].freeze

  TEXT_RESULTS = %w(Completed Received).freeze
  TEXT_NEXT_ACTIONS = ['Text Again',
                       'Call', 'Email', 'Message',
                       'Talk to In Person',
                       'Cultivate Relationship',
                       'Appointment Scheduled',
                       'Partner - Financial',
                       'Partner - Special',
                       'Partner - Pray',
                       'Ask in Future',
                       'Not Interested',
                       'None',
                       'Prayer Request',
                       'Thank'].freeze

  TALK_TO_IN_PERSON_RESULTS = %w(Completed).freeze
  TALK_TO_IN_PERSON_NEXT_ACTIONS = ['Talk to In Person Again',
                                    'Call', 'Email', 'Message', 'Text',
                                    'Cultivate Relationship',
                                    'Appointment Scheduled',
                                    'Partner - Financial',
                                    'Partner - Special',
                                    'Partner - Pray',
                                    'Ask in Future',
                                    'Not Interested',
                                    'None',
                                    'Prayer Request',
                                    'Thank'].freeze

  PRAYER_REQUEST_RESULTS = %w(Completed).freeze
  PRAYER_REQUEST_NEXT_ACTIONS = ['Prayer Request',
                                 'Call', 'Email', 'Message', 'Text',
                                 'Talk to In Person',
                                 'Cultivate Relationship',
                                 'Appointment Scheduled',
                                 'Partner - Financial',
                                 'Partner - Special',
                                 'Partner - Pray',
                                 'Ask in Future',
                                 'Not Interested',
                                 'None',
                                 'Thank'].freeze

  PRE_CALL_LETTER_NEXT_ACTIONS = ['Call to Follow Up',
                                  'Email',
                                  'Text',
                                  'Message',
                                  'Talk to In Person',
                                  'None'].freeze

  REMINDER_LETTER_NEXT_ACTIONS = PRE_CALL_LETTER_NEXT_ACTIONS
  SUPPORT_LETTER_NEXT_ACTIONS = PRE_CALL_LETTER_NEXT_ACTIONS

  STANDRD_NEXT_ACTIONS = [_('None')].freeze

  MESSAGE_RESULTS = [_('Done'), _('Received')].freeze
  STANDARD_RESULTS = [_('Done')].freeze

  ALL_RESULTS = STANDARD_RESULTS + APPOINTMENT_RESULTS + CALL_RESULTS + MESSAGE_RESULTS + TALK_TO_IN_PERSON_RESULTS + PRAYER_REQUEST_RESULTS

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
    when 'Pre Call Letter'
      PRE_CALL_LETTER_NEXT_ACTIONS
    when 'Reminder Letter'
      REMINDER_LETTER_NEXT_ACTIONS
    when 'Support Letter'
      SUPPORT_LETTER_NEXT_ACTIONS
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
    options['Pre Call Letter'] = PRE_CALL_LETTER_NEXT_ACTIONS
    options['Reminder Letter'] = REMINDER_LETTER_NEXT_ACTIONS
    options['Support Letter'] = SUPPORT_LETTER_NEXT_ACTIONS
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
    options['Prayer Request'] = PRAYER_REQUEST_RESULTS
    options['default'] = STANDARD_RESULTS
    options
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
    return if result.present? || Time.now > start_at || no_date

    account_list.google_integrations.each do |google_integration|
      google_integration.lower_retry_async(:sync_task, id)
    end
  end
end
