class MailChimpMailerPreview < ApplicationPreview
  def invalid_email_addresses
    email = 'thanos@gmail.com'
    contact1 = FactoryGirl.create(:contact_with_person, account_list: account_list)
    contact1.primary_person.update(email: email)
    contact2 = FactoryGirl.create(:contact_with_person, account_list: account_list)
    contact2.primary_person.update(email: email)

    emails_with_person_ids = {
      email => [contact1.primary_person.id, contact2.primary_person.id]
    }

    MailChimpMailer.invalid_email_addresses(user.account_lists.first.id, emails_with_person_ids)
  end
end
