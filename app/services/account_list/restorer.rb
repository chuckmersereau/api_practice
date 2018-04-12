# This class is designed to copy an account_list from an instance
# running against a backup DB to production using Kirby
class AccountList::Restorer
  attr_reader :account_list, :store

  def self.restore(id)
    AccountList::Restorer.new(id).store.each do |table_name, ids|
      RowTransferRequest.transfer(table_name, ids)
    end
  end

  def initialize(account_list_id)
    @account_list = AccountList.find(account_list_id)
    @store = {}
    fetch_records
  end

  private

  def fetch_records
    fetch_account_list_records
    fetch_company_records
    fetch_donor_account_records
    fetch_person_records
    fetch_contact_records
    fetch_activity_records
    fetch_designation_profile_records
    fetch_appeal_records
    fetch_duplicate_record_pair_records
    fetch_import_records
    fetch_mailchimp_account_records
    fetch_pls_account_records
    fetch_prayer_letters_account_records
    fetch_notification_records
    fetch_tag_records
    fetch_google_records
  end

  def add_to_store(klass, *ids)
    klass = klass.is_a?(Class) ? klass.table_name : klass
    ids = ids.flatten
    @store[klass] ||= []
    @store[klass] = (@store[klass] + ids).uniq.compact
  end

  def fetch_account_list_records
    add_to_store(
      AccountList,
      account_list.id
    )
    add_to_store(
      AccountListCoach,
      account_list.account_list_coaches.pluck(:id)
    )
    add_to_store(
      AccountListEntry,
      account_list.account_list_entries.pluck(:id)
    )
    add_to_store(
      AccountListInvite,
      account_list.account_list_invites.pluck(:id)
    )
    add_to_store(
      AccountListUser,
      account_list.account_list_users.pluck(:id)
    )
  end

  def fetch_company_records
    add_to_store(
      MasterCompany,
      account_list.people.joins(donor_accounts: [:master_company]).pluck('master_companies.id'),
      account_list.contacts.joins(donor_accounts: [:master_company]).pluck('master_companies.id'),
      account_list.companies.joins(:master_company).pluck('master_companies.id')
    )
    add_to_store(
      Company,
      account_list.companies.pluck(:id),
      account_list.people.joins(:companies).pluck('companies.id')
    )
    add_to_store(
      CompanyPartnership,
      account_list.company_partnerships.pluck(:id)
    )
  end

  def fetch_donor_account_records
    add_to_store(
      MasterPerson,
      account_list.people.joins(:master_person).pluck('master_people.id')
    )
    add_to_store(
      MasterPersonSource,
      account_list.people
                  .joins(master_person: [:master_person_sources])
                  .pluck('master_person_sources.id')
    )
    donor_account_ids = (
      account_list.people.joins(:donor_accounts).pluck('donor_accounts.id') +
      account_list.contacts.joins(:donor_accounts).pluck('donor_accounts.id') +
      account_list.contacts.joins(addresses: [:source_donor_account]).pluck('donor_accounts.id')
    ).uniq
    add_to_store(
      DonorAccount,
      donor_account_ids
    )
    add_to_store(
      MasterPersonDonorAccount,
      DonorAccount.where(id: donor_account_ids)
                  .joins(:master_person_donor_accounts)
                  .pluck('master_person_donor_accounts.id')
    )
  end

  def fetch_person_records
    add_to_store(
      Person,
      account_list.people.pluck(:id)
    )
    add_to_store(
      CompanyPosition,
      CompanyPosition.where(person: account_list.people).pluck(:id)
    )
    add_to_store(
      Person::FacebookAccount,
      account_list.people.joins(:facebook_accounts).pluck('person_facebook_accounts.id')
    )
    add_to_store(
      Person::GoogleAccount,
      account_list.people.joins(:google_accounts).pluck('person_google_accounts.id')
    )
    add_to_store(
      Person::KeyAccount,
      account_list.people.joins(:key_accounts).pluck('person_relay_accounts.id')
    )
    add_to_store(
      Person::LinkedinAccount,
      account_list.people.joins(:linkedin_accounts).pluck('person_linkedin_accounts.id')
    )
    add_to_store(
      Person::RelayAccount,
      account_list.people.joins(:relay_accounts).pluck('person_relay_accounts.id')
    )
    add_to_store(
      Person::TwitterAccount,
      account_list.people.joins(:twitter_accounts).pluck('person_twitter_accounts.id')
    )
    add_to_store(
      Person::Website,
      account_list.people.joins(:websites).pluck('person_websites.id')
    )
    add_to_store(
      PhoneNumber,
      account_list.people.joins(:phone_numbers).pluck('phone_numbers.id')
    )
    add_to_store(
      EmailAddress,
      account_list.people.joins(:email_addresses).pluck('email_addresses.id')
    )
    add_to_store(
      Picture,
      account_list.people.joins(:pictures).pluck('pictures.id')
    )
    add_to_store(
      DonorAccountPerson,
      account_list.people.joins(:donor_account_people).pluck('donor_account_people.id')
    )
    add_to_store(
      FamilyRelationship,
      account_list.people.joins(:family_relationships).pluck('family_relationships.id')
    )
  end

  def fetch_contact_records
    add_to_store(
      Contact,
      account_list.contacts.pluck(:id)
    )
    add_to_store(
      ContactReferral,
      account_list.contacts.joins(:contact_referrals_to_me).pluck('contact_referrals.id'),
      account_list.contacts.joins(:contact_referrals_by_me).pluck('contact_referrals.id')
    )
    add_to_store(
      ContactPerson,
      account_list.contacts.joins(:contact_people).pluck('contact_people.id')
    )
    add_to_store(
      ContactDonorAccount,
      account_list.contacts.joins(:contact_donor_accounts).pluck('contact_donor_accounts.id')
    )
    add_to_store(
      ContactNotesLog,
      account_list.contacts.joins(:contact_notes_logs).pluck('contact_notes_logs.id')
    )
    add_to_store(
      MasterAddress,
      account_list.contacts.joins(addresses: [:master_address]).pluck('master_addresses.id')
    )
    add_to_store(
      Address,
      account_list.contacts.joins(:addresses).pluck('addresses.id')
    )
    add_to_store(
      PartnerStatusLog,
      account_list.contacts.joins(:partner_status_logs).pluck('partner_status_logs.id')
    )
  end

  def fetch_activity_records
    add_to_store(
      Activity,
      account_list.activities.pluck(:id)
    )
    add_to_store(
      ActivityComment,
      account_list.activities.joins(:comments).pluck('activity_comments.id')
    )
    add_to_store(
      ActivityContact,
      account_list.activities.joins(:activity_contacts).pluck('activity_contacts.id')
    )
  end

  def fetch_designation_profile_records
    add_to_store(
      DesignationProfile,
      account_list.designation_profiles.pluck(:id)
    )
    add_to_store(
      DesignationAccount,
      account_list.designation_profiles.joins(:designation_accounts).pluck('designation_accounts.id')
    )
    add_to_store(
      Balance,
      account_list.designation_profiles.joins(designation_accounts: [:balances]).pluck('balances.id'),
      account_list.designation_profiles.joins(:balances).pluck('balances.id')
    )
    add_to_store(
      DesignationProfileAccount,
      account_list.designation_profiles.joins(:designation_profile_accounts).pluck('designation_profile_accounts.id')
    )
    add_to_store(
      Donation,
      account_list.designation_profiles.joins(designation_accounts: [:donations]).pluck('donations.id')
    )
  end

  def fetch_appeal_records
    add_to_store(
      Appeal,
      account_list.appeals.pluck(:id)
    )
    add_to_store(
      AppealContact,
      account_list.appeals.joins(:appeal_contacts).pluck('appeal_contacts.id')
    )
    add_to_store(
      Appeal::ExcludedAppealContact,
      account_list.appeals.joins(:excluded_appeal_contacts).pluck('appeal_excluded_appeal_contacts.id')
    )
    add_to_store(
      Pledge,
      account_list.pledges.pluck(:id)
    )
    add_to_store(
      PledgeDonation,
      account_list.pledges.joins(:pledge_donations).pluck('pledge_donations.id')
    )
  end

  def fetch_duplicate_record_pair_records
    add_to_store(
      DuplicateRecordPair,
      account_list.duplicate_record_pairs.pluck(:id)
    )
  end

  def fetch_import_records
    add_to_store(
      Import,
      account_list.imports.pluck(:id)
    )
  end

  def fetch_mailchimp_account_records
    add_to_store(
      MailChimpAccount,
      account_list.mail_chimp_account.id
    )
    add_to_store(
      MailChimpMember,
      account_list.mail_chimp_account.mail_chimp_members.pluck(:id)
    )
    add_to_store(
      MailChimpAppealList,
      MailChimpAppealList.where(mail_chimp_account: account_list.mail_chimp_account).pluck(:id)
    )
  end

  def fetch_pls_account_records
    add_to_store(
      PlsAccount,
      account_list.pls_account.id
    )
  end

  def fetch_prayer_letters_account_records
    add_to_store(
      PrayerLettersAccount,
      account_list.prayer_letters_account.id
    )
  end

  def fetch_notification_records
    add_to_store(
      NotificationPreference,
      account_list.notification_preferences.pluck(:id)
    )
    add_to_store(
      Notification,
      account_list.contacts.joins(:notifications).pluck('notifications.id'),
      account_list.activities.joins(:notification).pluck('notifications.id')
    )
  end

  def fetch_tag_records
    add_to_store(
      ActsAsTaggableOn::Tag,
      account_list.contacts.joins(taggings: [:tag]).pluck('tags.id'),
      account_list.activities.joins(taggings: [:tag]).pluck('tags.id')
    )
    add_to_store(
      ActsAsTaggableOn::Tagging,
      account_list.contacts.joins(:taggings).pluck('taggings.id'),
      account_list.activities.joins(:taggings).pluck('taggings.id')
    )
  end

  def fetch_google_records
    google_contact_ids =
      account_list.people.joins(:google_contacts).pluck('google_contacts.id')
    google_email_ids =
      account_list.activities.joins(:google_emails).pluck('google_emails.id')

    add_to_store(
      Person::GoogleAccount,
      account_list.google_integrations.pluck(:google_account_id),
      GoogleContact.where(id: google_contact_ids).pluck(:google_account_id),
      GoogleEmail.where(id: google_email_ids).pluck(:google_account_id)
    )
    add_to_store(
      Picture,
      GoogleContact.where(id: google_contact_ids).pluck(:picture_id)
    )
    add_to_store(
      GoogleContact,
      google_contact_ids
    )
    add_to_store(
      GoogleIntegration,
      account_list.google_integrations.pluck(:id),
      account_list.activities.joins(google_events: [:google_integration]).pluck('google_integrations.id')
    )
    add_to_store(
      GoogleEmail,
      google_email_ids
    )
    add_to_store(
      GoogleEvent,
      account_list.activities.joins(:google_events).pluck('google_events.id')
    )
    add_to_store(
      GoogleEmailActivity,
      account_list.activities.joins(:google_email_activities).pluck('google_email_activities.id')
    )
    add_to_store(
      GooglePlusAccount,
      account_list.people.joins(email_addresses: [:google_plus_account]).pluck('google_plus_accounts.id')
    )
  end
end
