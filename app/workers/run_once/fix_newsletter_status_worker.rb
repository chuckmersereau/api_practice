class RunOnce::FixNewsletterStatusWorker
  include Sidekiq::Worker
  List = Struct.new(:id, :name, :web_id)

  MAIL_CHIMP_REFACTOR_DATE = '2017-07-12'.freeze
  NEW_LIST_NAME = 'List created by MPDX'.freeze
  TAG_NAME = 'MailChimp Updated'.freeze

  sidekiq_options queue: :run_nowhere, unique: :until_executed

  def perform(mail_chimp_account_uuid)
    log('Starting work on ' + mail_chimp_account_uuid)
    @account = MailChimpAccount.find_by(uuid: mail_chimp_account_uuid)
    return if @account.api_key.blank? || @account.primary_list_id.blank?
    return unless @account.account_list

    @gibbon_wrapper = MailChimp::GibbonWrapper.new(@account)
    @list_id = @account.primary_list_id
    @current_subscribers = []
    @people = {}
    @contacts = {}
    members_to_resubscribe = find_members_to_resubscribe

    if @current_subscribers.to_set != members_to_resubscribe.to_set
      # If the current and new list of emails aren't the same, rather than mark all these people as subscribed on
      # someone's current mailchimp list, we're going to create a new list for them just to be safe. We'll add all these
      # emails to the new list, and attach that list to their
      # MPDX account.
      @new_list_id = create_new_list
      populate_new_list(@new_list_id, members_to_resubscribe)

      # We now want to point the mailchimp account at the new list. Otherwise when we automatically update mpdx
      # fields below it will pass through to updating the old list
      connect_mpdx_to_new_list(@new_list_id)
    end

    # Then update mpdx optout and send_newsletter values, which will trigger updates to the list we just pointed to
    # (all of those updates should be noops)
    update_mpdx_fields(members_to_resubscribe)

    @account.update(active: true) if @new_list_id

    log('-- running full sync on list')
    MailChimp::ExportContactsWorker.new.perform(@account.id, @new_list_id, nil)

    fix_count = FixCount.find_or_initialize_by(account_list_id: @account.account_list_id)
    fix_count.old_members = @current_subscribers.count
    fix_count.new_members = members_to_resubscribe.count
    fix_count.contacts_tagged = @account.account_list.contacts.tagged_with(TAG_NAME).count
    fix_count.people_changed = @people.keys.count
    fix_count.contacts_changed = @contacts.keys.count
    fix_count.save

    emails = @account.account_list.users.collect(&:email_address).uniq.compact
    return unless emails.any?
    log("-- emailing #{emails}")
    mail = if @new_list
             RunOnceMailer.new_mailchimp_list(emails,
                                              fix_count.contacts_tagged,
                                              @account.account_list.name,
                                              link_for_list)
           elsif fix_count.contacts_tagged.positive?
             RunOnceMailer.fix_newsletter_status(emails, fix_count.contacts_tagged, @account.account_list.name)
           end
    mail&.deliver_later
  rescue Gibbon::MailChimpError => e
    log("-- failing with #{e.status_code} #{e.detail}")
    case e.status_code
    when 401, 403
      @account.update(api_key: nil)
    when 404
      @account.update(primary_list_id: nil)
    else
      raise e
    end
  end

  # Returns a list of email addresses that received a newsletter since the refactor
  def find_members_to_resubscribe
    log('-- Finding people to resubscribe')
    members = @gibbon_wrapper.list_members(@list_id)

    members_to_resubscribe = []
    members.each do |member|
      if member['status'] == 'subscribed'
        @current_subscribers << member
        members_to_resubscribe << member
        next
      end

      # if they manually unsubscribed, they will have a reason other than Unsubscribed by an admin
      # we should not resubscribe them if that is the case
      mpdx_unsubscribe = member['unsubscribe_reason'] == 'N/A (Unsubscribed by an admin)'

      # if the email isn't a primary, it doesn't belong on the list anyway
      next unless primary_email_exists?(member['email_address'])

      unless mpdx_unsubscribe
        # if they have an unsubscribe reason other than via admin and are unsubscribed, ensure
        # optout_enewsletter is true
        ensure_optout(member['email_address']) if member['status'] == 'unsubscribed'

        # if the member is not currently unsubscribed and not unsubscribed by MPDX, leave them off
        # the new list
        next
      end

      activity_search_params = { params: {
        action: 'sent', fields: 'activity.timestamp'
      } }
      activity = @gibbon_wrapper.gibbon.lists(@list_id).members(member['id']).activity.retrieve(activity_search_params)['activity'].first

      members_to_resubscribe << member if activity && activity['timestamp'] >= MAIL_CHIMP_REFACTOR_DATE
    end

    members_to_resubscribe
  end

  def primary_email_exists?(email)
    email_address_scope = EmailAddress.joins(person: [:contacts])
                                      .where(contacts: {
                                               account_list_id: @account.account_list_id,
                                               status: Contact::ACTIVE_STATUSES + [nil]
                                             })
    email_address_scope.exists?(email: email, primary: true)
  end

  def emails_to_resubscribe(members_to_resubscribe)
    members_to_resubscribe.collect { |member| member['email_address'] }
  end

  def ensure_optout(email)
    people = @account.account_list
                     .people
                     .joins(:email_addresses)
                     .where(email_addresses: { email: email, primary: true })
    people.each { |person| person.update(optout_enewsletter: true) }
  end

  # resets the optout_newsletter and send_newsletter fields based on the fact that people are getting the letter
  def update_mpdx_fields(members_to_resubscribe)
    log('-- Updating MPDX fields')
    emails = emails_to_resubscribe(members_to_resubscribe)
    account_list = @account.account_list

    # Remove optout from people with this email address
    people = account_list.active_people.joins(:email_addresses).where('email_addresses.email' => emails.map(&:downcase))
    people.each do |person|
      next unless person.optout_enewsletter?
      person.update(optout_enewsletter: false)
      @people[person] ||= true
      add_tag(person.contacts.first)
    end

    # Update contacts on the list to get Email
    contact_scope = account_list.active_contacts.joins(:contact_people).where('contact_people.person_id' => people.pluck(:id))
    contact_scope.each do |contact|
      if contact.send_newsletter == 'Physical'
        contact.update(send_newsletter: 'Both')
        @contacts[contact] ||= true
        add_tag(contact)
      end

      next unless [nil, '', 'None'].include?(contact.send_newsletter)
      contact.update(send_newsletter: 'Email')
      @contacts[contact] ||= true
      add_tag(contact)
    end

    # Update contacts not on the list to not get email
    # no_email_contact_scope = account_list.active_contacts.where('id NOT IN(?)', contact_scope.pluck(:id))
    # no_email_contact_scope.where(send_newsletter: 'Both').update_all(send_newsletter: 'Physical')
    # no_email_contact_scope.where(send_newsletter: 'Email').update_all(send_newsletter: 'None')
  end

  def create_new_list
    log('-- creating a new mailchimp list')
    primary_list = @gibbon_wrapper.gibbon.lists(@list_id).retrieve
    # See if we already created the list
    @new_list = @gibbon_wrapper.lists.detect { |l| l.name == NEW_LIST_NAME }
    unless @new_list
      list_config_keys = %w[contact permission_reminder use_archive_bar campaign_defaults notify_on_subscribe
                            notify_on_unsubscribe email_type_option visibility]
      list_attributes = primary_list.slice(*list_config_keys).merge('name' => NEW_LIST_NAME)
      response = @gibbon_wrapper.gibbon.lists.create(body: list_attributes)
      @new_list = List.new(response['id'], response['name'], response['web_id'])
    end

    @new_list.id
  end

  def populate_new_list(list_id, members_to_resubscribe)
    log('-- populating new mailchimp list')
    emails = emails_to_resubscribe(members_to_resubscribe)
    gibbon = @gibbon_wrapper.gibbon
    # Since this list is fully managed by MPDX, it's safe to delete people before re-populating as part of this
    # one-off process
    existing_members = @gibbon_wrapper.list_members(list_id)
    existing_members.each do |member|
      gibbon.lists(list_id).members(member['id']).delete unless emails.include?(member['email_address'])
    end

    # Subscribe people to this new list
    operations = []
    member_attributes = %w[email_address email_type merge_fields language vip]
    members_to_resubscribe.each do |member|
      operations << {
        method: 'PUT',
        path: "lists/#{list_id}/members/#{@account.email_hash(member['email_address'])}",
        body: member.slice(*member_attributes).merge(status: 'subscribed').to_json
      }
    end

    if operations.present?
      gibbon.batches.create(body: { operations: operations })
    end
  end

  def connect_mpdx_to_new_list(list_id)
    @account.update(primary_list_id: list_id)
  end

  def add_tag(contact)
    contact.tag_list.add(TAG_NAME)
    contact.save
  end

  def link_for_list
    "#{@gibbon_wrapper.lists_link}members/?id=#{@new_list.web_id}"
  end

  def log(message)
    # Because the sidekiq config sets the logging level to Fatal, log to fatal
    # so that we can see these in the logs
    Rails.logger.fatal("FixNewsletterStatus[worker]: #{message}")
  end
end
