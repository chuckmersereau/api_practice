class AccountList::Analytics < ActiveModelSerializers::Model
  include ActiveModel::Validations

  validates :account_list,
            :start_date,
            :end_date,
            presence: true

  PERMITTED_ATTRIBUTES = [
    :account_list,
    :start_date,
    :end_date
  ].freeze

  attr_accessor :account_list,
                :start_date,
                :end_date

  def initialize(attributes = {})
    super

    after_initialize
  end

  def start_date=(value)
    @start_date = value.is_a?(Time) ? value : Time.iso8601(value.to_s).utc
  end

  def end_date=(value)
    @end_date = value.is_a?(Time) ? value : Time.iso8601(value.to_s).utc
  end

  def appointments
    @appointments ||= {
      completed: task_count(activity_type: 'Appointment', with_result: %w(Completed Done))
    }
  end

  def contacts
    @contacts ||= {
      active: account_list.contacts.where(status: ['Never Contacted', 'Contact for Appointment']).count,
      referrals: account_list.contacts
                             .joins(:contact_referrals_to_me).uniq
                             .where('contact_referrals.created_at BETWEEN ? AND ?', start_date, end_date)
                             .count,
      referrals_on_hand: account_list.contacts.where(status: [nil,
                                                              'Never Contacted',
                                                              'Ask in Future',
                                                              'Cultivate Relationship',
                                                              'Contact for Appointment'])
                                     .joins(:contact_referrals_to_me).uniq.count
    }
  end

  def correspondence
    @correspondence ||= {
      precall:         task_count(activity_type: 'Pre Call Letter', with_result: %w(Completed Done)),
      reminders:       task_count(activity_type: 'Reminder Letter', with_result: %w(Completed Done)),
      support_letters: task_count(activity_type: 'Support Letter',  with_result: %w(Completed Done)),
      thank_yous:      task_count(activity_type: 'Thank',           with_result: %w(Completed Done))
    }
  end

  def electronic
    @electronic ||= {
      appointments: task_count(activity_type: ['Email', 'Facebook Message', 'Text Message'], next_action: 'Appointment'),
      received:     email[:received] + facebook[:received] + text_message[:received],
      sent:         email[:sent] + facebook[:sent] + text_message[:sent]
    }
  end

  def email
    @email ||= {
      received: task_count(activity_type: 'Email', with_result: 'Received'),
      sent:     task_count(activity_type: 'Email', with_result: %w(Completed Done))
    }
  end

  def facebook
    @facebook ||= {
      received: task_count(activity_type: 'Facebook Message', with_result: 'Received'),
      sent:     task_count(activity_type: 'Facebook Message', with_result: %w(Completed Done))
    }
  end

  def phone
    @phone ||= {
      appointments:   task_count(activity_type: ['Call', 'Talk to In Person'], next_action: 'Appointment'),
      attempted:      task_count(activity_type: 'Call',  with_result: ['Attempted - Left Message', 'Attempted']),
      completed:      task_count(activity_type: 'Call',  with_result: %w(Completed Done)),
      received:       task_count(activity_type: 'Call',  with_result: 'Received'),
      talktoinperson: task_count(activity_type: 'Talk to In Person')
    }
  end

  def text_message
    @text_message ||= {
      received: task_count(activity_type: 'Text Message', with_result: 'Received'),
      sent:     task_count(activity_type: 'Text Message', with_result: %w(Completed Done))
    }
  end

  private

  def after_initialize
    raise ArgumentError, errors.full_messages.join(', ') if invalid?
  end

  def tasks_scope
    @tasks_scope ||= account_list.tasks.completed_between(start_date, end_date)
  end

  def task_count(activity_type:, with_result: nil, next_action: nil)
    task_query = tasks_scope.of_type(activity_type)
    task_query = task_query.with_result(with_result) if with_result.present?
    task_query = task_query.where(next_action: next_action) if next_action.present?
    task_query.count
  end
end
