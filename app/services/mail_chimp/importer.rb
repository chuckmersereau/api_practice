class MailChimp::Importer
  attr_reader :mail_chimp_account, :account_list, :gibbon_wrapper

  def initialize(mail_chimp_account)
    @mail_chimp_account = mail_chimp_account
    @account_list = mail_chimp_account.account_list
    @gibbon_wrapper = MailChimp::GibbonWrapper.new(mail_chimp_account)
  end

  def import_all_members
    MailChimp::ConnectionHandler.new(mail_chimp_account)
                                .call_mail_chimp(self, :import_all_members!)
  end

  def import_all_members!
    all_emails_to_import = fetch_all_emails_to_import

    import_members_by_emails(all_emails_to_import)
  end

  private

  def self.email_to_name(email)
    email[/[^@]+/].split(/[.\-_]/).map(&:capitalize).join(' ')
  end

  private_class_method :email_to_name

  def import_members_by_emails(member_emails)
    subscribed_members = list_of_members_info(member_emails).select do |member_info|
      member_info[:status] == 'subscribed'
    end

    formatted_subscribed_members = subscribed_members.map(&method(:format_member_info))

    import_members(formatted_subscribed_members)
  end

  def list_of_members_info(member_emails)
    gibbon_wrapper.list_member_info(mail_chimp_account.primary_list_id, member_emails)
                  .map(&:with_indifferent_access)
  end

  def format_member_info(member_info)
    {
      email: member_info['email_address'],
      first_name: nil_if_hex_chars(member_info['merge_fields']['FNAME']),
      last_name: nil_if_hex_chars(member_info['merge_fields']['LNAME']),
      greeting: nil_if_hex_chars(member_info['merge_fields']['GREETING']),
      groupings: member_info['merge_fields']['GROUPINGS'],
      status: member_info['status']
    }
  end

  # Some users have unexpected random hex values in their mailchimp accounts:
  # https://secure.helpscout.net/conversation/207704672/57384/?folderId=378967
  # I'm not sure as to the cause yet, but one simple thing we can do now is to
  # recognize the pattern (string of 12 hex chars) and then in that case don't
  # use the name/greeting field from mailchimp in the `format_member_info`.
  def nil_if_hex_chars(name)
    name =~ /[0-9a-f]{12}/ ? nil : name
  end

  def fetch_all_emails_to_import
    gibbon_wrapper.list_emails(mail_chimp_account.primary_list_id) -
      mail_chimp_account.relevant_emails
  end

  def import_members(member_infos)
    matching_people_hash = Matcher.new(mail_chimp_account).find_matching_people(member_infos)

    import_matched(matching_people_hash)
    import_unmatched(member_infos, matching_people_hash)
  end

  def person_by_name_with_no_email(first_name, last_name)
    person = account_list.people.find_by(first_name: first_name, last_name: last_name)
    person if person.try(:primary_email_address).nil?
  end

  def import_matched(matching_people_hash)
    matching_people_hash.each do |person_id, member_info|
      add_person_to_newsletter(Person.find(person_id), member_info[:email])
    end
  end

  def import_unmatched(member_infos, matching_people_hash)
    member_infos_to_add = member_infos - matching_people_hash.values.map(&:symbolize_keys)

    member_infos_to_add.each do |member_info|
      add_person_to_newsletter(create_person(member_info), member_info[:email])
    end
  end

  def add_person_to_newsletter(person, email)
    add_contact_to_newsletter(person.contact)
    person.update(email: email)
  end

  def add_contact_to_newsletter(contact)
    return if mail_chimp_account.sync_all_active_contacts?

    contact.update(send_newsletter: (contact.send_newsletter == 'Physical' ? 'Both' : 'Email'))
  end

  def create_person(member)
    first_name = member[:first_name] || self.class.email_to_name(member[:email])

    person = Person.create(first_name: first_name, last_name: member[:last_name])

    person.contacts << contact_from_member(member)

    person
  end

  def contact_from_member(member)
    grouping = member[:groupings].try(:first) || {}
    group_status = grouping['groups'].try(:split, ',').try(:first)

    acceptable_group_status = group_status.in?(Contact::ASSIGNABLE_STATUSES) ? group_status : 'Partner - Pray'

    account_list.contacts.create(
      name: contact_name(member[:first_name], member[:last_name], member[:email]),
      notes: 'Imported from MailChimp',
      greeting: member[:greeting],
      status: acceptable_group_status
    )
  end

  def contact_name(first_name, last_name, email)
    if first_name.present? && last_name.present?
      "#{last_name}, #{first_name}"
    else
      first_name.presence || last_name.presence || self.class.email_to_name(email)
    end
  end

  def gibbon_list
    gibbon_wrapper.gibbon_list_object(mail_chimp_account.primary_list_id)
  end
end
