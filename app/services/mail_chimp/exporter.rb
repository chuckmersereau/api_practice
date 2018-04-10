# This class handles the process of exporting MPDX data to Mail Chimp.
class MailChimp::Exporter
  attr_reader :mail_chimp_account, :gibbon_wrapper, :list_id

  def initialize(mail_chimp_account, list_id = nil)
    @mail_chimp_account = mail_chimp_account
    @gibbon_wrapper = MailChimp::GibbonWrapper.new(mail_chimp_account)
    @list_id = list_id || mail_chimp_account.primary_list_id
  end

  def export_contacts(contact_ids = nil, ignore_status = false)
    MailChimp::ConnectionHandler.new(mail_chimp_account)
                                .call_mail_chimp(self, :export_contacts!, contact_ids, ignore_status)
  end

  def export_contacts!(contact_ids, ignore_status)
    contacts_to_export = fetch_contacts_to_export(contact_ids, ignore_status)

    # on non-primary lists, all of the subscriptions should be manual, so they shouldn't be auto-cleaned
    emails_of_members_to_remove = fetch_emails_of_members_to_remove if primary_list?

    export_adds_and_updates(contacts_to_export) if contacts_to_export.present?
    export_deletes(emails_of_members_to_remove) if emails_of_members_to_remove.present?
  end

  private

  def primary_list?
    @list_id == mail_chimp_account.primary_list_id
  end

  def appeal_export?
    @appeal_id.present?
  end

  def export_adds_and_updates(contacts)
    group_adder.add_status_interests(statuses_from_contacts(contacts))
    group_adder.add_tags_interests(tags_from_contacts(contacts))

    merge_variables_to_add.each do |merge_variable|
      merge_field_adder.add_merge_field(merge_variable)
    end
    batcher.subscribe_contacts(contacts)
  end

  def export_deletes(emails_of_members_to_remove)
    emails_with_reasons = emails_of_members_to_remove.each_with_object({}) do |email, hash|
      reason = unsubscribe_reason(email)
      hash[email] = reason
    end

    batcher.unsubscribe_members(emails_with_reasons)
  end

  def unsubscribe_reason(email)
    # newsletter: none/physical
    return 'email on contact with newsletter set to None or Physical' if non_opt_out_people_emails.exists?(email: email)
    # opt-out
    return "email on person marked as 'Opt-out of Email Newsletter'" if primary_emails.exists?(email: email)
    # non-primary
    return 'email marked as non-primary' if active_emails.exists?(email: email)
    # historic email
    return 'email marked as historic' if mpdx_email_addresses.exists?(email: email)
    # not in mpdx
    'email not in MPDX'
  end

  def mpdx_email_addresses
    EmailAddress.joins(person: [:contacts]).where(contacts: { account_list_id: mail_chimp_account.account_list.id })
  end

  def active_emails
    mpdx_email_addresses.where(historic: false)
  end

  def primary_emails
    active_emails.where(primary: true)
  end

  def non_opt_out_people_emails
    primary_emails.where(people: { optout_enewsletter: false })
  end

  def group_adder
    @group_adder ||= InterestAdder.new(mail_chimp_account, gibbon_wrapper, list_id)
  end

  def batcher
    @batcher ||= Batcher.new(mail_chimp_account, gibbon_wrapper, list_id)
  end

  def merge_field_adder
    @merge_field_adder ||= MergeFieldAdder.new(mail_chimp_account, gibbon_wrapper, list_id)
  end

  def fetch_emails_of_members_to_remove
    relevant_mail_chimp_members.pluck(:email).map(&:downcase).uniq - mail_chimp_account.newsletter_emails
  end

  def fetch_contacts_to_export(contact_ids, ignore_status)
    relevant_contact_scope = mail_chimp_account.relevant_contacts(contact_ids, ignore_status)
                                               .includes(primary_contact_person: :person, people: :primary_email_address)
    relevant_contact_scope.find_each.select { |contact| contact_changed_or_new?(contact) }.sort_by(&:created_at)
  end

  def statuses_from_contacts(contacts)
    (contacts.map(&:status).compact + ['Partner - Pray']).uniq
  end

  def tags_from_contacts(_contacts)
    mail_chimp_account.account_list.contact_tags.pluck(:name).uniq
  end

  def merge_variables_to_add
    ['GREETING'].concat(appeal_export? ? ['DONATED_TO_APPEAL'] : [])
  end

  def fetch_members_to_unsubscribe(contacts)
    gibbon_wrapper.list_emails(list_id) - primary_email_addresses_scope(contacts).pluck(:email)
  end

  def primary_email_addresses_scope(contacts)
    EmailAddress.joins(person: :contact_people)
                .where(contact_people: { contact_id: contacts.ids }, primary: true)
  end

  def contact_changed_or_new?(contact)
    contact.people.any? do |person|
      next unless person.primary_email_address
      member = members_by_email[person.primary_email_address.email]
      contact_person_changed_or_new?(contact, person, member)
    end
  end

  def contact_person_changed_or_new?(contact, person, member)
    member.nil? ||
      member.status != contact.status ||
      member.greeting != contact.greeting ||
      member.first_name != person.first_name ||
      member.last_name != person.last_name ||
      member.contact_locale != contact.locale
  end

  def members_by_email
    @members_by_email ||= relevant_mail_chimp_members.map { |member| { member.email.downcase => member } }.reduce({}, :merge)
  end

  def relevant_mail_chimp_members
    @relevant_mail_chimp_members ||= mail_chimp_account.mail_chimp_members.where(list_id: list_id)
  end

  def gibbon_list
    gibbon_wrapper.gibbon_list_object(list_id)
  end
end
