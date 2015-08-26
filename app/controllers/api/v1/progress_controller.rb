class Api::V1::ProgressController < Api::V1::BaseController
  ACTIVE_STATUSES_FOR_STAT = ['Never Contacted', 'Contact for Appointment', '', nil]

  def index
    if params[:start_date]
      @start_date = Date.parse(params[:start_date])
    else
      @start_date = Date.today.beginning_of_week
    end
    @end_date = @start_date.end_of_week

    @counts = {
      phone: {
        completed: task_count('Call', %w(Completed Done)),
        attempted: task_count('Call', ['Attempted - Left Message', 'Attempted']),
        received: task_count('Call', 'Received'),
        appointments: task_count(['Call', 'Talk to In Person'], nil, 'Appointment Scheduled'),
        talktoinperson: all_tasks.of_type('Talk to In Person').count
      },
      email: {
        sent: task_count('Email', %w(Completed Done)),
        received: task_count('Email', 'Received')
      },
      facebook: {
        sent: task_count('Facebook Message', %w(Completed Done)),
        received: task_count('Facebook Message', 'Received')
      },
      text_message: {
        sent: task_count('Text Message', %w(Completed Done)),
        received: task_count('Text Message', 'Received')
      },
      electronic: {
        sent: 0,
        received: 0,
        appointments: task_count(['Email', 'Facebook Message', 'Text Message'], nil, 'Appointment Scheduled')
      },
      appointments: {
        completed: task_count('Appointment', %w(Completed Done))
      },
      correspondence: {
        precall: task_count('Pre Call Letter', 'Done'),
        support_letters: task_count('Support Letter', 'Done'),
        thank_yous: task_count('Thank', 'Done'),
        reminders: task_count('Reminder Letter', 'Done')
      },
      contacts: contact_counts
    }
    @counts[:electronic][:sent] = calc_electronic_count(:sent)
    @counts[:electronic][:received] = calc_electronic_count(:received)

    render json: @counts, callback: params[:callback]
  end

  protected

  def all_tasks
    current_account_list.tasks.completed_between(@start_date, @end_date)
  end

  def task_count(type, result, next_action = nil)
    q = all_tasks.of_type(type)
    q = q.with_result(result) if result.present?
    q = q.where(next_action: next_action) if next_action.present?
    q.count
  end

  def contact_counts
    {
      active: current_account_list.contacts
        .where(status: ACTIVE_STATUSES_FOR_STAT)
        .count,
      referrals: current_account_list.contacts
        .created_between(@start_date, @end_date)
        .joins(:contact_referrals_to_me).uniq
        .count,
      referrals_on_hand: current_account_list.contacts
        .joins(:contact_referrals_to_me).uniq
        .where(status: Contact::IN_PROGRESS_STATUSES)
        .count
    }
  end

  def calc_electronic_count(result)
    @counts[:email][result] + @counts[:facebook][result] + @counts[:text_message][result]
  end
end
