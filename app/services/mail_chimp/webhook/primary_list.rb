# This class holds all the methods associated to the Mail Chimp webhooks that are linked to the primary list of a Mail Chimp Account.
module MailChimp::Webhook
  class PrimaryList < Base
    def subscribe_hook(email)
      MailChimp::MembersImportWorker.perform_async(mail_chimp_account.id, [email])

      @account_list.people.joins(:email_addresses).where(email_addresses: { email: email, primary: true })
                   .update_all(optout_enewsletter: false)
    end

    def unsubscribe_hook(email)
      # No need to trigger a callback because MailChimp has already unsubscribed this email
      account_list.people.joins(:email_addresses).where(email_addresses: { email: email, primary: true })
                  .update_all(optout_enewsletter: true)
    end

    def email_update_hook(old_email, new_email)
      ids_of_people_to_update = @account_list.people.joins(:email_addresses)
                                             .where(email_addresses: { email: old_email, primary: true }).pluck(:id)

      Person.where(id: ids_of_people_to_update).includes(:email_addresses).each do |person|
        update_person_email(person, old_email, new_email)
      end
    end

    def email_cleaned_hook(email, reason)
      return unsubscribe_hook(email) if reason == 'abuse'

      MailChimp::Webhook::Base::EmailBounceHandler.new(account_list, email, reason).handle_bounce
    end

    private

    def update_person_email(person, old_email, new_email)
      old_email_record = person.email_addresses.find_by(email: old_email)
      new_email_record = person.email_addresses.find_by(email: new_email)

      if new_email_record
        new_email_record.update(primary: true)
      else
        person.email_addresses.create(email: new_email, primary: true)
      end
      old_email_record.update(primary: false)
    end
  end
end
