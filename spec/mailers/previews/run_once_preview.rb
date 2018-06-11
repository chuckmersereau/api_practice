class RunOncePreview < ApplicationPreview
  def fix_newsletter_status
    RunOnceMailer.fix_newsletter_status('bill.bright@cru.org', 12, 'Staff Account')
  end

  def new_mailchimp_list
    RunOnceMailer.new_mailchimp_list('bill.bright@cru.org', 12, 'Staff Account', 'https://us1.admin.mailchimp.com/lists/members/?id=1234')
  end

  def gdpr_unsubscribes
    contact = account_list.contacts.first || FactoryGirl.create(:contact, account_list: account_list)
    person = contact.people.first || FactoryGirl.create(:person, contacts: [contact])
    email = person.primary_email_address || FactoryGirl.create(:email_address, primary: true, person: person)
    unsubscribe = RunOnce::SendGDPRUnsubscribesWorker.new.build_unsubscribes_list(account_list, [email]).first

    RunOnceMailer.gdpr_unsubscribes('bill@cru.org', account_list.name, unsubscribe)
  end
end
