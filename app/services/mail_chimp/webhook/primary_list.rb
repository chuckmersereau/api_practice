# This class holds all the methods associated to the Mail Chimp webhooks that are linked to the primary list of a Mail Chimp Account.
module MailChimp::Webhook
  class PrimaryList < Base
    def subscribe_hook(email)
      people_to_subscribe = account_list.people.joins(:email_addresses).where(email_addresses: { email: email, primary: true })

      return MailChimp::MembersImportWorker.perform_async(mail_chimp_account.id, [email]) if people_to_subscribe.empty?

      contacts_of_people_to_subscribe = Contact.joins(:contact_people).where(contact_people: { person: people_to_subscribe })

      contacts_of_people_to_subscribe.where(send_newsletter: 'Physical').update_all(send_newsletter: 'Both')
      contacts_of_people_to_subscribe.where(send_newsletter: ['None', nil]).update_all(send_newsletter: 'Email')

      people_to_subscribe.update_all(optout_enewsletter: false)
    end

    def unsubscribe_hook(email, reason, list_id)
      unless reason == 'abuse'
        wrapper = MailChimp::GibbonWrapper.new(mail_chimp_account)
        member = wrapper.list_member_info(mail_chimp_account.primary_list_id, email).first
        return unless member
        mpdx_unsubscribe = member['unsubscribe_reason'] == 'N/A (Unsubscribed by an admin)'

        # don't trigger the opt-out update if mpdx or the list manager unsubscribed them
        return if member['status'] == 'subscribed' || mpdx_unsubscribe
      end

      people = account_list.people.joins(:email_addresses).where(email_addresses: { email: email, primary: true })

      # No need to trigger a callback because MailChimp has already unsubscribed this email
      people.update_all(optout_enewsletter: true)

      people.each do |person|
        next unless %w(Email Both).include? person.contact.send_newsletter
        next if person.contact.people.any? do |contact_person|
          # don't remove newsletter status if there are any other
          # people who are not opted out who have email addresses
          !contact_person.optout_enewsletter && contact_person.email_addresses.any?
        end

        person.contact.update(send_newsletter: person.contact.send_newsletter == 'Both' ? 'Physical' : nil)
      end

      clean_up_members(email, list_id)
    end

    def email_update_hook(old_email, new_email)
      ids_of_people_to_update = @account_list.people.joins(:email_addresses)
                                             .where(email_addresses: { email: old_email, primary: true }).pluck(:id)

      Person.where(id: ids_of_people_to_update).includes(:email_addresses).each do |person|
        update_person_email(person, old_email, new_email)
      end
    end

    def email_cleaned_hook(email, reason, list_id)
      return unsubscribe_hook(email, reason, list_id) if reason == 'abuse'

      MailChimp::Webhook::Base::EmailBounceHandler.new(account_list, email, reason).handle_bounce

      clean_up_members(email, list_id)
    end

    private

    def clean_up_members(email, list_id)
      mail_chimp_account.mail_chimp_members.where(list_id: list_id, email: email).each(&:destroy)
    end

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
