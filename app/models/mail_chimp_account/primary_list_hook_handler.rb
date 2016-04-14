class MailChimpAccount
  class PrimaryListHookHandler < BaseHookHandler
    def subscribe_hook(email)
      @mc_account.queue_import_new_member(email)
    end

    def unsubscribe_hook(email)
      # No need to trigger a callback because MailChimp has already unsubscribed this email
      @account_list.people.joins(:email_addresses).where(email_addresses: { email: email, primary: true })
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
      EmailBounceHandler.new(@account_list, email, reason).handle_bounce
    end

    private

    def update_person_email(person, old_email, new_email)
      old_email_record = person.email_addresses.find { |e| e.email == old_email }
      new_email_record = person.email_addresses.find { |e| e.email == new_email }

      if new_email_record
        new_email_record.primary = true
      else
        person.email_addresses.build(email: new_email, primary: true)
      end
      old_email_record.primary = false
      person.save!
    end
  end
end
