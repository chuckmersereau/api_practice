require 'google_contact_sync'
require 'google_contacts_cache'

class GoogleContactsIntegrator
  attr_accessor :assigned_remote_ids, :cache, :client

  CONTACTS_GROUP_TITLE = 'MPDX'

  # If a contact in MPDX gets marked as inactive, e.g. 'Not Interested', then they won't be synced with Google anymore
  # but they will be assigned to this Google group so the user can delete it if they want to.
  INACTIVE_GROUP_TITLE = 'Inactive'

  # Caching the Google contacts from one big request speeds up the sync as we don't need separate HTTP get requests
  # But is only worth it if we are syncing a number of contacts, so check the number against this threshold.
  CACHE_ALL_G_CONTACTS_THRESHOLD = 10

  # The Google sync will wait for any running Google and Facebook imports to finish first to reduce the chance of
  # unexpected behavior of a sync and an import running at the same time. These constants configure how often to check
  # for the imports being done and when to just cancel this queuing of the Google contacts sync due to an import
  # not being finished. (The sync would get re-queued after another contact is saved though).
  SECS_BETWEEN_CHECK_FOR_IMPORTS_DONE = 30
  MAX_CHECKS_FOR_IMPORTS_DONE = 60

  def initialize(google_integration)
    @integration = google_integration
    @account = google_integration.google_account
  end

  def self.retry_on_api_errs
    yield
  rescue GoogleContactsApi::UnauthorizedError
    # Try job again which will refresh the token
    raise LowerRetryWorker::RetryJobButNoAirbrakeError
  rescue OAuth2::Error => e
    if e.response && e.response.status >= 500 || e.response.status == 403 # Server errs or rate limit exceeded
      # For the rate limit error, we need to wait up to an hour, so we should put the job in the retry queue
      # rather than holding up a Sidekiq thread with a long retry, but don't report the error to Airbrake since these
      # errors are expected from time to time.
      raise LowerRetryWorker::RetryJobButNoAirbrakeError
    else
      raise e
    end
  end

  def sync_contacts
    return if @integration.account_list.organization_accounts.any?(&:downloading)
    return if @integration.account_list.imports.any?(&:importing)
    return if @integration.account_list.mail_chimp_account.try(&:importing)
    sync_and_return_num_synced
    cleanup_inactive_g_contacts
  rescue Person::GoogleAccount::MissingRefreshToken
    # Don't log this exception as we expect it to happen from time to time.
    # Person::GoogleAccount will turn off the contacts integration and send the user an email to refresh their Google login.
  rescue => e
    Airbrake.raise_or_notify(e)
  end

  def sync_and_return_num_synced
    @cache = GoogleContactsCache.new(@account)
    contacts = contacts_to_sync
    return 0 if contacts.empty?

    setup_assigned_remote_ids
    @contacts_to_retry_sync = []

    # Each individual google_contact record also tracks a last synced time which will reflect when that particular person
    # was synced as well, this integration overall sync time is used though for querying the Google Contacts API for
    # updated google contacts, so setting the last synced time at the start of th sync would capture Google contacts
    # changed during the sync in the next sync.
    @integration.contacts_last_synced = Time.now

    contacts.each(&method(:sync_contact))
    self.class.retry_on_api_errs { api_user.send_batched_requests }

    # For contacts syncs to the Google Contacts API that were either deleted or modified during the sync
    # and so caused a 404 Contact Not Found or a 412 Precondition Mismatch (i.e. ETag mismatch, i.e. contact changed),
    # we can attempt to retry them by re-executing the sync logic which will pull down the Google Contacts information
    # and re-compare with it. The save_g_contacts_then_links method below may populate @contacts_to_retry_sync.
    # Only retry the sync once though in case one of those problems was caused by something that would be ongoing
    # despite re-applying the sync logic.
    @contacts_to_retry_sync.each(&:reload)
    @contacts_to_retry_sync.each(&method(:sync_contact))
    self.class.retry_on_api_errs { api_user.send_batched_requests }

    delete_g_contact_merge_losers

    @integration.save

    contacts.size
  end

  def delete_g_contact_merge_losers
    g_contact_merge_losers.each(&method(:delete_g_contact_merge_loser))
  end

  def g_contact_merge_losers
    # Return the google_contacts for this Google account that are no longer associated with a contact-person pair
    # due to that contact or person being merged with another contact or person in MPDX.
    # Look for records that have both the contact_id and person_id set, because the Google Import uses an old method
    # of just setting the person_id and we don't want to wrongly interpret imported Google contacts as merge losers.
    @account.google_contacts
      .joins('LEFT JOIN contact_people ON '\
        'google_contacts.person_id = contact_people.person_id AND contact_people.contact_id = google_contacts.contact_id')
      .where('contact_people.id IS NULL').where.not(contact_id: nil).where.not(person_id: nil).readonly(false)
  end

  def delete_g_contact_merge_loser(g_contact_link)
    if g_contact_link.remote_id
      self.class.retry_on_api_errs { api_user.delete_contact(g_contact_link.remote_id) }
    end
    g_contact_link.destroy
  rescue => e
    if defined?(e.response) && GoogleContactsApi::Api.parse_response_code(e.response) == 404
      # If a 404 error occurred it means the remote Google contact was already deleted, so just delete the link
      g_contact_link.destroy
    else
      # Otherwise we couldn't successfully delete the remote Google Contact, so keep the link to try deleting again later
      Airbrake.raise_or_notify(e)
    end
  end

  def cleanup_inactive_g_contacts
    GoogleContact.joins(:contact).where(contacts: { account_list_id: @integration.account_list.id })
      .where(Contact.inactive_conditions).where(google_account: @account).readonly(false)
      .each(&method(:cleanup_inactive_g_contact))
    api_user.send_batched_requests
  end

  def cleanup_inactive_g_contact(g_contact_link, num_retries = 1)
    g_contact = @cache.find_by_id(g_contact_link.remote_id)
    unless g_contact
      g_contact_link.destroy
      return
    end

    g_contact.prep_add_to_group(inactive_group)
    api_user.batch_create_or_update(g_contact) do |status|
      inactive_cleanup_response(status, g_contact, g_contact_link, num_retries)
    end
  end

  def inactive_cleanup_response(status, g_contact, g_contact_link, num_retries)
    case status[:code]
    when 200, 404
      # For success or contact not found, just go ahead and delete the link
      g_contact_link.destroy
    when 412
      fail status.inspect if num_retries < 1
      # For 412 Etags Mismatch, remove the cached Google contact and retry the operation again
      @cache.remove_g_contact(g_contact)
      cleanup_inactive_g_contact(g_contact_link, num_retries - 1)
    else
      fail status.inspect
    end
  rescue => e
    Airbrake.raise_or_notify(e)
  end

  def api_user
    @account.contacts_api_user
  end

  def setup_assigned_remote_ids
    @assigned_remote_ids = @integration.account_list.contacts.joins(:people)
                           .joins('INNER JOIN google_contacts ON google_contacts.person_id = people.id')
                           .pluck('google_contacts.remote_id').to_set
  end

  def contacts_to_sync
    if @integration.contacts_last_synced
      updated_g_contacts = self.class.retry_on_api_errs do
        api_user.contacts_updated_min(@integration.contacts_last_synced, showdeleted: false)
      end

      queried_contacts_to_sync = contacts_to_sync_query(updated_g_contacts)
      if queried_contacts_to_sync.length > CACHE_ALL_G_CONTACTS_THRESHOLD
        @cache.cache_all_g_contacts
      else
        @cache.cache_g_contacts(updated_g_contacts)
      end

      queried_contacts_to_sync
    else
      # Cache all contacts for the initial sync as all active MPDX contacts will need to be synced so most likely worth it.
      @cache.cache_all_g_contacts
      @integration.account_list.active_contacts
    end
  end

  # Queries all contacts that:
  # - Have some associted records updated_at more recent than its google_contact.contacts_last_synced
  # - Or contacts without associated google_contacts records (i.e. which haven't been synced before)
  # - Or contacts whose google_contacts records have been updated remotely since the last sync as specified by the
  #   updated_g_contacts list
  def contacts_to_sync_query(updated_g_contacts)
    updated_link_ids = updated_g_contact_links(updated_g_contacts).map(&:id)

    @integration.account_list.active_contacts
      .joins(:people)
      .joins("LEFT JOIN addresses ON addresses.addressable_id = contacts.id AND addresses.addressable_type = 'Contact'")
      .joins('LEFT JOIN email_addresses ON people.id = email_addresses.person_id')
      .joins('LEFT JOIN phone_numbers ON people.id = phone_numbers.person_id')
      .joins('LEFT JOIN person_websites ON people.id = person_websites.person_id')
      .joins('LEFT JOIN google_contacts ON google_contacts.person_id = people.id AND google_contacts.contact_id = contacts.id '\
          "AND google_contacts.google_account_id = #{quote_sql(@account.id)}")
      .group('contacts.id, google_contacts.last_synced, google_contacts.id')
      .having('google_contacts.last_synced IS NULL ' \
        'OR google_contacts.last_synced < ' \
            'GREATEST(contacts.updated_at, MAX(contact_people.updated_at), MAX(people.updated_at), MAX(addresses.updated_at), ' \
                'MAX(email_addresses.updated_at), MAX(phone_numbers.updated_at), MAX(person_websites.updated_at))' +
        (updated_link_ids.empty? ? '' : " OR google_contacts.id IN (#{quote_sql_list(updated_link_ids)})"))
      .distinct
      .readonly(false)
  end

  # Finds Google contact link record that have been remotely modified since their last sync given a list of recently
  # modified remote Google contacts
  def updated_g_contact_links(updated_g_contacts)
    updated_remote_ids = updated_g_contacts.map(&:id)
    return [] if updated_remote_ids.empty? # Need to check after map as updated_g_contacts is GoogleContactsApi::ResultSet

    g_contacts_by_id = Hash[updated_g_contacts.map { |g_contact| [g_contact.id, g_contact] }]
    g_contact_links = GoogleContact.select(:id, :remote_id, :last_synced)
                      .where(google_account: @account).where(remote_id: updated_remote_ids).where.not(last_synced: nil).to_a

    g_contact_links.select do |g_contact_link|
      g_contact = g_contacts_by_id[g_contact_link.remote_id]
      g_contact.updated > g_contact_link.last_synced
    end
  end

  def quote_sql_list(list)
    list.map { |item| ActiveRecord::Base.connection.quote(item) }.join(',')
  end

  def quote_sql(sql)
    ActiveRecord::Base.connection.quote(sql)
  end

  def sync_contact(contact)
    g_contacts_and_links = contact.contact_people.joins(:person)
                           .order('contact_people.primary::int desc').order(:person_id)
                           .map(&method(:get_g_contact_and_link))
    return if g_contacts_and_links.empty?

    GoogleContactSync.sync_contact(contact, g_contacts_and_links)
    contact.save(validate: false)

    g_contacts_to_save = g_contacts_and_links.select(&method(:g_contact_needs_save?)).map(&:first)
    if g_contacts_to_save.empty?
      save_g_contact_links(g_contacts_and_links)
    else
      save_g_contacts_then_links(contact, g_contacts_to_save, g_contacts_and_links)
    end
  rescue => e
    Airbrake.raise_or_notify(e, parameters: { contact_id: contact.id, last_batch_xml: api_user.last_batch_xml })
  end

  def get_g_contact_and_link(contact_person)
    g_contact_link =
      @account.google_contacts.where(person: contact_person.person, contact: contact_person.contact).first_or_initialize
    g_contact = get_or_query_g_contact(g_contact_link, contact_person.person)

    if g_contact
      @assigned_remote_ids << g_contact.id
    else
      g_contact = GoogleContactsApi::Contact.new
      g_contact_link.last_data = {}
    end
    g_contact.prep_add_to_group(my_contacts_group)
    g_contact.prep_add_to_group(mpdx_group)

    [g_contact, g_contact_link]
  end

  def groups
    @groups ||= self.class.retry_on_api_errs { api_user.groups }
  end

  def my_contacts_group
    @my_contacts_group ||= groups.find { |group| group.system_group_id == 'Contacts' }
  end

  def inactive_group
    @inactive_group ||= groups.find { |group| group.title == INACTIVE_GROUP_TITLE } ||
                        GoogleContactsApi::Group.create({ title: INACTIVE_GROUP_TITLE }, api_user.api)
  end

  def mpdx_group
    @mpdx_group ||= groups.find { |group| group.title == CONTACTS_GROUP_TITLE } ||
                    GoogleContactsApi::Group.create({ title: CONTACTS_GROUP_TITLE }, api_user.api)
  end

  def get_or_query_g_contact(g_contact_link, person)
    if g_contact_link.remote_id
      retrieved_g_contact = @cache.find_by_id(g_contact_link.remote_id)
      return retrieved_g_contact if retrieved_g_contact
    end

    @cache.select_by_name(person.first_name, person.last_name).find do |g_contact|
      !@assigned_remote_ids.include?(g_contact.id)
    end
  end

  def g_contact_needs_save?(g_contact_and_link)
    g_contact, g_contact_link = g_contact_and_link
    g_contact.attrs_with_changes != g_contact_link.last_data
  end

  def save_g_contacts_then_links(contact, g_contacts_to_save, g_contacts_and_links)
    retry_sync = false

    g_contacts_to_save.each_with_index do |g_contact, index|
      g_contact_link = g_contacts_and_links.find { |g_contact_and_link| g_contact_and_link.first == g_contact }.second

      # The Google Contacts API batch requests significantly speed up the sync by reducing HTTP requests
      api_user.batch_create_or_update(g_contact) do |status|
        # This block is called for each saved g_contact once its batch completes
        begin
          # If any g_contact save failed but can be retried, then mark that we should queue the MPDX contact for a retry
          # sync once we get to the last associated g_cotnact
          retry_sync = true if failed_but_can_retry?(status, g_contact, g_contact_link)

          # When we get to last associated g_contact, then either save or queue for retry the MPDX contact
          next unless index == g_contacts_to_save.size - 1
          if retry_sync
            @contacts_to_retry_sync << contact
          else
            save_g_contact_links(g_contacts_and_links)
          end
        rescue LowerRetryWorker::RetryJobButNoAirbrakeError => e
          raise e
        rescue => e
          # Rescue within this block so that the exception won't cause the response callbacks for the whole batch to break
          Airbrake.raise_or_notify(e, parameters: { g_contact_attrs: g_contact.formatted_attrs,
                                                    batch_xml: api_user.last_batch_xml })
        end
      end
    end
  end

  def failed_but_can_retry?(status, g_contact_saved, g_contact_link)
    case status[:code]
    when 200, 201
      # Didn't fail, so by the method semantics, return false
      return false
    when 404, 412
      # 404 is Not found, the google contact was deleted since the last sync
      # 412 is Precondition Failed (ETag mismatch), so the google contact was changed since the sync was started

      # Correct the cache to reflect that this contact has been modified or deleted and so shouldn't be cached
      @cache.remove_g_contact(g_contact_saved)

      if status[:code] == 404
        # If the contact was not found, delete the associated g_contact_link record, so we'll recreate a Google Contact
        # on retry
        g_contact_link.destroy
      else
        # If the Google Contact was modified during the sync operation, set the last synced time to nul to force
        # re-comparing with the updated Google contact
        g_contact_link.update(last_synced: nil)
      end

      return true
    when 403
      # 403 is user rate limit exceeded, so don't retry the particular contact, just queue the whole job for retry
      fail LowerRetryWorker::RetryJobButNoAirbrakeError
    else
      # Failed but can't just fix by resyncing the contact, so raise an error
      fail(status.inspect)
    end
  end

  def save_g_contact_links(g_contacts_and_links)
    g_contacts_and_links.each do|g_contact_and_link|
      g_contact, g_contact_link = g_contact_and_link
      @assigned_remote_ids.add(g_contact.id)
      g_contact_link.update(last_data: g_contact.formatted_attrs, remote_id: g_contact.id, last_etag: g_contact.etag, last_synced: Time.now)
    end
  end
end
