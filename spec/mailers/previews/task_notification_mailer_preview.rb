class TaskNotificationMailerPreview < ApplicationPreview
  def notify
    @contacts = account_list.contacts.limit(2)
    if @contacts.empty?
      @contacts << account_list.contacts.create(name: 'Ryan & Sarah, Connor')
      @contacts << account_list.contacts.create(name: 'Mike & Johanna, Smith')
    end
    @task = account_list.tasks.create(
      subject: 'Call for Decision',
      start_at: Time.current,
      activity_type: 'Call',
      location: '142 Emailer Road, Railstown',
      contacts: @contacts
    )
    TaskNotificationMailer.notify(@task.id, user.id)
  end
end
