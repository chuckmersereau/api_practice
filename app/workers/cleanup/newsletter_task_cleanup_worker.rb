class Cleanup::NewsletterTaskCleanupWorker
  include Sidekiq::Worker

  # we normally don't put things in this queue because it is only run by one legacy worker (we had one
  # queue reserved for mpdx classic that we haven't repurposed yet), but it seems logical to use it for this.
  sidekiq_options queue: :default

  # provide a comment if you want a way to group these actions in the audit logs
  # provide a before_date if you want to only delete things created before a certain date
  def perform(account_list_id, comment = nil, before_date = nil)
    bad_tasks = Task.where(account_list_id: account_list_id,
                           activity_type: ['Newsletter - Physical', 'Newsletter - Email'],
                           remote_id: nil)
                    .includes(:activity_contacts, :account_list)
    bad_tasks = bad_tasks.where('created_at < ?', before_date) if before_date

    bad_tasks.find_each { |task| destroy_task(task, comment) }
  end

  private

  def destroy_task(task, comment)
    Task.transaction do
      task.audit_comment = comment
      task.skip_contact_task_counter_update = true
      task.activity_contacts.each do |ac|
        ac.audit_comment = comment
        ac.skip_contact_task_counter_update = true
        ac.destroy
      end
      task.destroy
    end
  end
end
