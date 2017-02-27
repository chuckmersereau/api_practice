class MailChimpImport
  def initialize(mail_chimp_account)
    @mc_account = mail_chimp_account
    @account_list = @mc_account.account_list
  end

  def import_contacts
    import_members_by_emails(all_emails_to_import)
  rescue Gibbon::MailChimpError => e
    @mc_account.handle_newsletter_mc_error(e)
  end

  def import_members_by_emails(member_emails)
    members_info =
      @mc_account.list_member_info(@mc_account.primary_list_id, member_emails)
    formatted_info = members_info.map(&method(:format_member_info))
    subscribed_members = formatted_info.select { |i| i[:status] == 'subscribed' }
    import_members(subscribed_members)
  rescue Gibbon::MailChimpError => e
    @mc_account.handle_newsletter_mc_error(e)
  end

  def self.email_to_name(email)
    email[/[^@]+/].split(/[.\-_]/).map(&:capitalize).join(' ')
  end

  private

  def format_member_info(info)
    { email: info['email_address'],
      first_name: nil_if_hex_chars(info['merge_fields']['FNAME']),
      last_name: nil_if_hex_chars(info['merge_fields']['LNAME']),
      greeting: nil_if_hex_chars(info['merge_fields']['GREETING']),
      groupings: info['merge_fields']['GROUPINGS'],
      status: info['status'] }
  end

  # Some users have unexpected random hex values in their mailchimp accounts:
  # https://secure.helpscout.net/conversation/207704672/57384/?folderId=378967
  # I'm not sure as to the cause yet, but one simple thing we can do now is to
  # recognize the pattern (string of 12 hex chars) and then in that case don't
  # use the name/greeting field from mailchimp in the `format_member_info`.
  def nil_if_hex_chars(name)
    name =~ /[0-9a-f]{12}/ ? nil : name
  end

  def all_emails_to_import
    @mc_account.list_emails(@mc_account.primary_list_id) - @mc_account.relevant_emails
  end

  def import_members(members)
    matched_person_ids_map = person_ids_to_members(members)
    matched_person_ids_map = reject_extra_subscribe_causers(matched_person_ids_map)
    import_matched(matched_person_ids_map)
    import_unmatched(members, matched_person_ids_map)
  end

  def person_ids_to_members(members)
    person_ids_to_members = {}
    members.each do |member|
      person = find_person(member[:first_name], member[:last_name], member[:email])
      next unless person
      person_ids_to_members[person.id] ||= member
    end
    person_ids_to_members
  end

  def find_person(first_name, last_name, email)
    person_by_email(email) || person_by_name_with_no_email(first_name, last_name)
  end

  def person_by_email(email)
    @account_list.people.joins(:primary_email_address)
                 .find_by(email_addresses: { email: email })
  end

  def person_by_name_with_no_email(first_name, last_name)
    person = @account_list.people.find_by(first_name: first_name, last_name: last_name)
    person if person.try(:primary_email_address).nil?
  end

  def reject_extra_subscribe_causers(matched_person_ids_map)
    contacts = @account_list.contacts.joins(:people)
                            .where(people: { id: matched_person_ids_map.keys }).distinct

    contacts_with_extras = contacts.select do |contact|
      extra_emails_if_subscribed?(contact, matched_person_ids_map)
    end

    matched_person_ids_map.except(*contacts_with_extras.flat_map(&:people).map(&:id))
  end

  def extra_emails_if_subscribed?(contact, matched_person_ids_map)
    return false if contact.send_newsletter.in?(%w(Email Both))
    contact.people.any? do |person|
      person.primary_email_address.present? && !person.optout_enewsletter? &&
        !matched_person_ids_map.include?(person.id)
    end
  end

  def import_matched(matched_person_ids_map)
    matched_person_ids_map.each do |person_id, member|
      add_person_to_newsletter(Person.find(person_id), member[:email])
    end
  end

  def add_person_to_newsletter(person, email)
    add_contact_to_newsletter(person.contact)
    person.email = email
    person.save!
  rescue ActiveRecord::RecordInvalid
    nil
  end

  def add_contact_to_newsletter(contact)
    return if @mc_account.sync_all_active_contacts?
    send_newsletter = contact.send_newsletter == 'Physical' ? 'Both' : 'Email'
    contact.update!(send_newsletter: send_newsletter)
  end

  def import_unmatched(members, matched_person_ids_map)
    members_to_add = members - matched_person_ids_map.values
    members_to_add.each do |member|
      person = create_person(member)
      add_person_to_newsletter(person, member[:email])
    end
  end

  def create_person(member)
    first_name = if member[:first_name].present?
                   member[:first_name]
                 else
                   self.class.email_to_name(member[:email])
                 end

    person = Person.create(first_name: first_name, last_name: member[:last_name])

    person.contacts << contact_from_member(member)
    person
  end

  def contact_from_member(member)
    contact = @account_list.contacts.build(
      name: contact_name(member[:first_name], member[:last_name], member[:email]),
      notes: 'Imported from MailChimp', greeting: member[:greeting]
    )

    grouping = member[:groupings].try(:first) || {}
    group_status = grouping['groups'].try(:split, ',').try(:first)
    contact.status = group_status if group_status.in?(contact.assignable_statuses)
    contact.status ||= 'Partner - Pray'
    contact.save

    contact
  end

  def contact_name(first_name, last_name, email)
    if first_name.present? && last_name.present?
      "#{last_name}, #{first_name}"
    elsif first_name.present?
      first_name
    elsif last_name.present?
      last_name
    else
      self.class.email_to_name(email)
    end
  end
end