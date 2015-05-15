class Api::V1::ProgressController < Api::V1::BaseController
  def index
    if params[:start_date]
      @start_date = Date.parse(params[:start_date])
    else
      @start_date = Date.today.beginning_of_week
    end
    @end_date = @start_date.end_of_week

    counts = {
      phone: {
        completed: all_tasks.of_type('Call')
                   .with_result(%w(Completed Done))
                   .count,
        attempted: all_tasks.of_type('Call')
                   .with_result(['Attempted - Left Message', 'Attempted'])
                   .count,
        received: all_tasks.of_type('Call')
                  .with_result('Received')
                  .count,
        appointments: all_tasks.of_type(['Call', 'Talk to In Person'])
                      .where(next_action: 'Appointment Scheduled')
                      .count,
        talktoinperson: all_tasks.of_type('Talk to In Person').count
      },
      email: {
        sent: all_tasks.of_type('Email')
              .with_result(%w(Completed Done))
              .count,
        received: all_tasks.of_type('Email')
                  .with_result('Received')
                  .count
      },
      facebook: {
        sent: all_tasks.of_type('Facebook Message')
              .with_result(%w(Completed Done))
              .count,
        received: all_tasks.of_type('Facebook Message')
                  .with_result('Received')
                  .count
      },
      text_message: {
        sent: all_tasks.of_type('Text Message')
              .with_result(%w(Completed Done))
              .count,
        received: all_tasks.of_type('Text Message')
                  .with_result('Received')
                  .count
      },
      electronic: {
        sent: 0,
        received: 0,
        appointments: all_tasks.of_type(['Email', 'Facebook Message', 'Text Message'])
                      .where(next_action: 'Appointment Scheduled')
                      .count
      },
      appointments: {
        completed: all_tasks.of_type('Appointment')
                   .with_result(%w(Completed Done))
                   .count
      },
      correspondence: {
        precall: all_tasks.of_type('Pre Call Letter')
                 .with_result('Done')
                 .count,
        support_letters: all_tasks.of_type('Support Letter')
                         .with_result('Done')
                         .count,
        thank_yous: all_tasks.of_type('Thank')
                    .with_result('Done')
                    .count,
        reminders: all_tasks.of_type('Reminder Letter')
                   .with_result('Done')
                   .count
      },
      contacts: {
        active: current_account_list.contacts
                .where(status: ['Never Contacted', 'Contact for Appointment', '', nil])
                .count,
        referrals: current_account_list.contacts
                   .created_between(@start_date, @end_date)
                   .joins(:contact_referrals_to_me).uniq
                   .count,
        referrals_on_hand: current_account_list.contacts.with_referrals
                           .where(status: Contact::IN_PROGRESS_STATUSES)
                           .count
      }
    }
    counts[:electronic][:sent] = counts[:email][:sent] +
                                 counts[:facebook][:sent] +
                                 counts[:text_message][:sent]
    counts[:electronic][:received] = counts[:email][:received] +
                                     counts[:facebook][:received] +
                                     counts[:text_message][:received]

    render json: counts, callback: params[:callback]
  end

  protected

  def all_tasks
    current_account_list.tasks.completed_between(@start_date, @end_date)
  end
end
