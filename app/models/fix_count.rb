# rubocop:disable Rails/ApplicationRecord
class FixCount < ActiveRecord::Base
  List = Struct.new(:id, :name)

  MAIL_CHIMP_REFACTOR_DATE = '2017-07-12'.freeze

  def self.run(id = nil)
    mc_accounts = MailChimpAccount.where('api_key is not null AND primary_list_id is not null')
    mc_accounts = mc_accounts.where(id: id) if id
    mc_accounts.each do |mc|
      RunOnce::FixCountsWorker.perform_async(mc.id)
    end
  end

  def run(mc)
    return if mc.api_key.blank? || mc.primary_list_id.blank?
    return unless mc.account_list
    zero
    @account = mc
    @gibbon_wrapper = MailChimp::GibbonWrapper.new(@account)
    @list_id = @account.primary_list_id
    @people = {}
    @contacts = {}
    @tagged = {}
    members_to_resubscribe = find_members_to_resubscribe

    update_mpdx_fields(members_to_resubscribe)

    self.new_members = members_to_resubscribe.length
    self.contacts_tagged = @tagged.keys.length
    self.people_changed = @people.keys.length
    self.contacts_changed = @contacts.keys.length
    self.account_list_id = mc.account_list_id
    save
  rescue Gibbon::MailChimpError => e
    case e.status_code
    when 401, 403
      mc.update(api_key: nil)
    when 404
      mc.update(primary_list_id: nil)
    else
      raise e
    end
  end

  def zero
    self.old_members = 0
    self.new_members = 0
    self.contacts_tagged = 0
    self.people_changed = 0
    self.contacts_changed = 0
  end

  def primary_email_exists?(email)
    email_address_scope = EmailAddress.joins(person: [:contacts])
                                      .where(contacts: {
                                               account_list_id: @account.account_list_id,
                                               status: Contact::ACTIVE_STATUSES + [nil]
                                             })
    email_address_scope.exists?(email: email, primary: true)
  end

  # Returns a list of email addresses that received a newsletter since the refactor
  def find_members_to_resubscribe
    members = @gibbon_wrapper.list_members(@list_id)

    members_to_resubscribe = []
    members.each do |member|
      self.old_members += 1 if member['status'] == 'subscribed'

      # if they manually unsubscribed, they will have a reason other than Unsubscribed by an admin
      # we should not resubscribe them if that is the case
      mpdx_unsubscribe = member['unsubscribe_reason'] == 'N/A (Unsubscribed by an admin)'

      # if the email isn't a primary, it doesn't belong on the list anyway
      next unless primary_email_exists?(member['email_address'])

      if member['status'] == 'subscribed'
        members_to_resubscribe << member
        # no need to check activity if currently subscribed and is primary email
        next
      end

      # if the member is not currently unsubscribed and not unsubscribed by MPDX, leave them off
      next unless mpdx_unsubscribe

      activity_search_params = { params: {
        action: 'sent', fields: 'activity.timestamp'
      } }
      activity = @gibbon_wrapper.gibbon.lists(@list_id).members(member['id']).activity.retrieve(activity_search_params)['activity'].first

      members_to_resubscribe << member if activity && activity['timestamp'] >= MAIL_CHIMP_REFACTOR_DATE
    end

    members_to_resubscribe
  end

  def emails_to_resubscribe(members_to_resubscribe)
    members_to_resubscribe.collect { |member| member['email_address'] }
  end

  # resets the optout_newsletter and send_newsletter fields based on the fact that people are getting the letter
  def update_mpdx_fields(members_to_resubscribe)
    emails = emails_to_resubscribe(members_to_resubscribe)
    account_list = @account.account_list

    # Remove optout from people with this email address
    people = account_list.active_people.joins(:email_addresses).where(
      'email_addresses.email' => emails.map(&:downcase),
      'email_addresses.primary' => true
    )
    people.each do |person|
      next unless person.optout_enewsletter?
      @people[person] ||= 0
      @people[person] += 1
      add_tag(person.contacts.first)
    end

    # Update contacts on the list to get Email
    contact_scope = account_list.active_contacts.joins(:contact_people).where('contact_people.person_id' => people.pluck(:id))
    contact_scope.each do |contact|
      next unless contact.send_newsletter == 'Physical' || [nil, '', 'None'].include?(contact.send_newsletter)
      @contacts[contact] ||= 0
      @contacts[contact] += 1
      add_tag(contact)
    end
  end

  def add_tag(contact)
    @tagged[contact] ||= 0
    @tagged[contact] += 1
  end
end
