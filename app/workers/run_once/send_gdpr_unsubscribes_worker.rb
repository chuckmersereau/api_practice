class RunOnce::SendGDPRUnsubscribesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: false

  def perform(email_addresses)
    emails = EmailAddress.includes(person: :contacts).where(email: email_addresses, primary: true,
                                                            people: { optout_enewsletter: false },
                                                            contacts: { send_newsletter: %w(Email Both) })

    AccountList.includes(people: :email_addresses).where(email_addresses: { id: emails.collect(&:id) })
               .each { |al| send_mail(al, emails) }
  end

  def build_unsubscribes_list(account_list, emails)
    contact_people = ContactPerson.includes(:contact, :person).where(contacts: { account_list_id: account_list.id },
                                                                     person_id: emails.collect(&:person_id))
    unsubscribes = contact_people.map do |cp|
      email = emails.find { |e| e.person_id == cp.person_id }
      { contact_id: cp.contact_id, person_id: cp.person.id, person_name: cp.person.to_s, email: email.email }
    end
    unsubscribes.sort_by { |h| h[:email] }
  end

  private

  def send_mail(account_list, emails)
    to = account_list.users.collect(&:email_address).uniq.compact
    return unless to.any?

    unsubscribes = build_unsubscribes_list(account_list, emails)

    unsubscribes.each { |unsub| RunOnceMailer.delay.gdpr_unsubscribes(to, account_list.name, unsub) }
    Rails.logger.warn("Account List notified of GDPR unsubscribes: #{account_list.id}")
  end
end
