class MailChimpAccount::Exporter
  MAILCHIMP_MAX_ALLOWD_MERGE_FIELDS = 30
  THRESHOLD_SIZE_FOR_BATCH_OPERATION = 3

  attr_reader :account, :list_id

  def initialize(account, list_id = nil)
    @account = account
    @list_id = list_id || @account.primary_list_id
    @use_primary_list = @account.primary_list_id == @list_id
    Gibbon::Request.api_key = @account.api_key
    Gibbon::Request.timeout = 600
  end

  def export_to_list(contacts)
    # Make sure we have an interest group for each status of the
    # partners set to receive the newsletter
    statuses = (contacts.map(&:status).compact + ['Partner - Pray']).uniq
    add_status_groups(statuses)

    # Make sure we have an interest group for each tag of the
    # partners set to receive the newsletter
    if $rollout.active?(:mailchimp_tags_export, account.account_list)
      tags = account.account_list.contact_tags
      add_tags_groups(tags)
    end

    add_greeting_merge_variable

    members_params = batch_params(contacts)
    list_batch_subscribe(members_params)
    create_member_records(members_params)
  end

  def export_appeal_contacts(contact_ids, appeal_id)
    return if use_primary_list?
    contacts = account.contacts_with_email_addresses(contact_ids)
    compare_and_unsubscribe(contacts)
    export_to_list(contacts)
    setup_webhooks
    save_appeal_list_info(appeal_id)
  end

  def export_to_primary_list
    setup_webhooks

    account.mail_chimp_members.where(list_id: list_id).destroy_all
    account.mail_chimp_members.reload

    MailChimpImport.new(account).import_contacts
    MailChimpSync.new(account).sync_contacts
  end

  # private

  def list_batch_subscribe(batch)
    if batch.size < THRESHOLD_SIZE_FOR_BATCH_OPERATION
      batch.each { |params| subscribe_member(params) }
    else
      operations = batch.map do |params|
        { method: 'PUT',
          path: "/lists/#{account.primary_list_id}/members/#{email_hash(params[:email_address])}",
          body: params.to_json }
      end
      gb.batches.create(body: { operations: operations })
    end
  end

  def compare_and_unsubscribe(contacts)
    # compare and unsubscribe email addresses from the prev mail chimp appeal list not on
    # the current one.
    members_to_unsubscribe = account.list_emails(list_id) - batch_params(contacts).map { |b| b[:email_address] }
    return if members_to_unsubscribe.empty?
    account.unsubscribe_list_batch(list_id, members_to_unsubscribe)
  end

  def batch_params(contacts)
    [].tap do |batch|
      contacts.each do |contact|
        contact.status = 'Partner - Pray' if contact.status.blank?
        contact.people.each do |person|
          batch << person_to_param(contact, person)
        end
      end
    end
  end

  def person_to_param(contact, person)
    params = {
      status_if_new: 'subscribed',
      email_address: person.primary_email_address.email,
      merge_fields: {
        EMAIL: person.primary_email_address.email, FNAME: person.first_name,
        LNAME: person.last_name, GREETING: contact.greeting
      }
    }

    params[:language] = contact.locale if contact.locale.present?

    if account.status_grouping_id.present?
      params[:interests] ||= {}
      params[:interests].merge! interests_for_status(contact.status)
    end

    if account.tags_grouping_id.present?
      params[:interests] ||= {}
      params[:interests].merge! interests_for_tags(contact.tag_list)
    end

    params
  end

  def add_greeting_merge_variable
    merge_fields = mc_list.merge_fields.retrieve['merge_fields']

    return if merge_fields.find { |m| m['tag'] == 'GREETING' } ||
              merge_fields.size == MAILCHIMP_MAX_ALLOWD_MERGE_FIELDS

    mc_list.merge_fields.create(
      body: {
        tag: 'GREETING', name: _('Greeting'), type: 'text'
      }
    )
  rescue Gibbon::MailChimpError => e
    # Check for the race condition of another thread having already added this
    return if e.detail =~ /Merge Field .* already exists/

    # If you try to add a merge field when list has 30 already, it gives 500 err
    if e.status_code == 500
      # Log the error but don't re-raise it
      Rollbar.error(e)
      return
    end
    raise e
  end

  def create_member_records(members_params)
    members_params.each do |params|
      member = account.mail_chimp_members.find_or_create_by(list_id: list_id,
                                                            email: params[:email_address])

      if params[:interests]
        status = status_for_interest_id(params[:interests])
        tags   = tags_for_interest_id(params[:interests])
      end

      member.update(first_name: params[:merge_fields][:FNAME],
                    last_name: params[:merge_fields][:LNAME],
                    greeting: params[:merge_fields][:GREETING],
                    status: status,
                    tags: tags)
    end
  end

  def subscribe_member(params)
    gb.lists(account.primary_list_id).members(email_hash(params[:email_address])).upsert(body: params)
  rescue Gibbon::MailChimpError => e
    raise unless MailChimpAccount.invalid_email_error?(e)
  end

  def add_status_groups(statuses)
    grouping = find_grouping(account.status_grouping_id, 'Partner Status')

    if grouping
      # make sure the grouping is hidden
      interest_categories(grouping['id']).update(body: { title: grouping['title'], type: 'hidden' })
    else
      # create a new grouping
      interest_categories.create(body: { title: _('Partner Status'), type: 'hidden' })
      grouping = find_grouping(account.status_grouping_id, 'Partner Status')
    end
    account.update_attribute(:status_grouping_id, grouping['id'])

    # Add any new groups
    groups = interest_categories(account.status_grouping_id).interests.retrieve['interests'].map { |i| i['name'] }
    create_interest_categories_for(account.status_grouping_id, statuses - groups)

    cache_status_interest_ids
  end

  def cache_status_interest_ids
    interests = interest_categories(account.status_grouping_id).interests.retrieve['interests']
    interests = Hash[interests.map { |interest| [interest['name'], interest['id']] }]
    account.update_attribute(:status_interest_ids, interests)
  end

  def interests_for_status(contact_status)
    cache_status_interest_ids if account.status_interest_ids.blank?

    Hash[account.status_interest_ids.map do |status, interest_id|
      [interest_id, status == _(contact_status)]
    end]
  end

  def status_for_interest_id(interests)
    return unless interests
    cache_status_interest_ids if account.status_interest_ids.blank?
    ids = interests.select { |_, v| v }.keys
    ids = account.status_interest_ids.values & ids
    account.status_interest_ids.invert[ids.first]
  end

  def add_tags_groups(tags)
    grouping = find_grouping(account.tags_grouping_id, 'Tags')
    if grouping
      # make sure the grouping is hidden
      interest_categories(grouping['id']).update(body: { title: grouping['title'], type: 'hidden' })
    else
      # create a new grouping
      interest_categories.create(body: { title: _('Tags'), type: 'hidden' })
      grouping = find_grouping(account.tags_grouping_id, 'Tags')
    end
    account.update_attribute(:tags_grouping_id, grouping['id'])

    # Add any new groups
    groups = interest_categories(account.tags_grouping_id).interests.retrieve['interests'].map { |i| i['name'] }
    create_interest_categories_for(account.tags_grouping_id, tags - groups)

    cache_tags_interest_ids
  end

  def cache_tags_interest_ids
    interests = interest_categories(account.tags_grouping_id).interests.retrieve['interests']
    interests = Hash[interests.map { |interest| [interest['name'], interest['id']] }]
    account.update_attribute(:tags_interest_ids, interests)
  end

  def interests_for_tags(tags)
    cache_tags_interest_ids if account.tags_interest_ids.blank?

    Hash[account.tags_interest_ids.map do |tag, interest_id|
      [interest_id, tags.include?(tag)]
    end]
  end

  def tags_for_interest_id(interests)
    return unless interests
    cache_tags_interest_ids if account.tags_interest_ids.blank?
    ids = interests.select { |_, v| v }.keys
    ids = account.tags_interest_ids.values & ids
    account.tags_interest_ids.invert.values_at(*ids)
  end

  def create_interest_categories_for(grouping_id, interests)
    interests.reject(&:blank?).each do |interest|
      begin
        interest_categories(grouping_id).interests.create(body: { name: interest })
      rescue Gibbon::MailChimpError => e
        next if e.status_code == 400 &&
                e.detail =~ /Cannot add .* because it already exists on the list/
        break if e.status_code == 400 &&
                 e.detail =~ /Cannot have more than .* interests per list/
        raise
      end
    end
  end

  def find_grouping(id, name)
    groupings = mc_list.interest_categories.retrieve['categories']
    groupings.find { |g| g['id'] == id } || groupings.find { |g| g['title'] == _(name) }
  rescue Gibbon::MailChimpError => e
    raise e unless e.message.include?('code 211') # This list does not have interest groups enabled (code 211)
    return nil
  end

  def save_appeal_list_info(appeal_id)
    account.build_mail_chimp_appeal_list unless account.mail_chimp_appeal_list
    account.mail_chimp_appeal_list.update(appeal_list_id: list_id, appeal_id: appeal_id)
  end

  def setup_webhooks
    # Don't setup webhooks when developing on localhost because MailChimp can't
    # verify the URL and so it makes the sync fail
    return if Rails.env.development? &&
              Rails.application.routes.default_url_options[:host].include?('localhost')

    return if account.webhook_token.present? &&
              mc_list.webhooks.retrieve['webhooks'].find { |w| w['url'] == webhook_url }

    account.update(webhook_token: SecureRandom.hex(32)) if account.webhook_token.blank?

    mc_list.webhooks.create(
      body: {
        url: webhook_url,
        events: { subscribe: true, unsubscribe: true, profile: true, cleaned: true,
                  upemail: true, campaign: true },
        sources: { user: true, admin: true, api: false }
      }
    )
  end

  def gb
    Gibbon::Request
  end

  def mc_list
    gb.lists(list_id)
  end
  delegate :interest_categories, to: :mc_list

  def use_primary_list?
    @use_primary_list
  end

  def email_hash(email)
    Digest::MD5.hexdigest(email.downcase)
  end

  def webhook_url
    (Rails.env.development? ? 'http://' : 'https://') +
      Rails.application.routes.default_url_options[:host] + '/mail_chimp_webhook/' + account.webhook_token
  end
end
