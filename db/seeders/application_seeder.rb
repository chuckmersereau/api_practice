require 'factory_girl'

class ApplicationSeeder
  attr_accessor :quiet

  def initialize(quiet = !Rails.env.development?)
    self.quiet = quiet
  end

  def seed
    intro
    2.times { seed_all_models }
    all_models_seeded?
    outro
  end

  def all_models_seeded?
    Rails.application.eager_load!
    unseeded = ActiveRecord::Base.descendants.reject do |klass|
      klass.anonymous? || klass.abstract_class? || klass.exists?
    end
    unseeded.each { |record_class| puts "Warning: No records seeded for class #{record_class}" } unless quiet
    unseeded.blank?
  end

  private

  def intro
    return if quiet
    puts '== Starting database seeding... ==============================================='
    puts "The database will be seeded using FactoryGirl factories.\nPrinting the name of each factory as it's created:"
  end

  def outro
    return if quiet
    puts "\n== Finished database seeding! ================================================="
  end

  def create(*args)
    print "#{args.first}... " unless quiet
    FactoryGirl.create(*args)
  end

  def seed_all_models
    # Seed NotificationTypes separately:
    require_relative 'notification_types_seeder'
    NotificationTypesSeeder.new(quiet).seed

    Rails.application.eager_load!
    ApplicationRecord.descendants.each(&:reset_column_information)

    # Create some fundamental records first so that we can reference them below to establish associations:

    organization = create :organization
    user = create :user_with_full_account
    account_list = user.account_lists.reload.last
    contact = create :contact_with_person, account_list: account_list
    person = contact.people.reload.last

    create :contact_referral, referred_by: contact, referred_to: create(:contact)
    create :contact_notes_log, contact: contact

    create :account_list_invite, account_list: account_list
    create :account_list_coach, account_list: account_list, coach: user.becomes(User::Coach)

    create :activity, account_list: account_list
    create :activity_comment, activity: Activity.last, person: person
    create :activity_contact, activity: Activity.last, contact: contact

    create :address, addressable: contact

    create :admin_impersonation_log, impersonator: user, impersonated: create(:user)
    create :admin_reset_log

    appeal = create(:appeal, account_list: account_list)
    create :appeal_contact, appeal: appeal, contact: contact
    create :appeal_excluded_appeal_contact, appeal: appeal, contact: contact

    create :company
    create :company_partnership, company: Company.last, account_list: account_list
    create :company_position, company: Company.last, person: person

    create(:currency_alias) unless CurrencyAlias.any?
    create(:currency_rate) unless CurrencyRate.any?

    create :donor_account, organization: organization
    create :contact_donor_account, contact: contact, donor_account: DonorAccount.last
    create :donor_account_person, donor_account: DonorAccount.last, person: person

    create :designation_account, organization: organization
    create :designation_profile_account, designation_profile: DesignationProfile.last, designation_account: DesignationAccount.last

    create :duplicate_contacts_pair, account_list: account_list
    create :duplicate_people_pair, account_list: account_list

    create :donation, donor_account: DonorAccount.last, designation_account: DesignationAccount.last
    create :pledge, account_list: account_list, contact: contact
    create :pledge_donation, pledge: Pledge.last, donation: Donation.last

    create :phone_number, person: person

    email_address = create :email_address, person: person
    create :google_plus_account, email_address: email_address

    create :event, account_list: account_list

    create :family_relationship, person: person, related_person: create(:person)

    create :google_account, person: person
    create :google_contact, person: person
    create :google_email, google_account: Person::GoogleAccount.last
    create :google_email_activity, google_email: GoogleEmail.last, activity: create(:activity, account_list: account_list)
    create :google_integration, account_list: account_list, google_account: Person::GoogleAccount.last, calendar_integration: false
    create :google_event, activity: create(:activity, account_list: account_list), google_integration: GoogleIntegration.last

    create :help_request, account_list: account_list

    create :import, account_list: account_list

    create :mail_chimp_account, account_list: account_list
    create :mail_chimp_appeal_list, mail_chimp_account: MailChimpAccount.last, appeal: Appeal.last
    create :mail_chimp_member, mail_chimp_account: MailChimpAccount.last

    create :master_address
    create :master_company
    create :master_person
    create :master_person_donor_account, master_person: MasterPerson.last, donor_account: DonorAccount.last
    create :master_person_source, master_person: MasterPerson.last, organization: organization

    create :message, account_list: account_list
    create :name_male_ratio
    create :nickname

    create :notification_preference, notification_type: NotificationType.last, account_list: account_list
    create :notification, contact: contact

    create :user_option, user: user

    create :partner_status_log, contact: contact

    create :facebook_account, person: person
    create :key_account, person: person
    create :linkedin_account, person: person
    create :relay_account, person: person
    create :twitter_account, person: person
    create :website, person: person

    create :picture, picture_of: person
    create :pls_account, account_list: account_list
    create :prayer_letters_account, account_list: account_list
    create :donation_amount_recommendation
    create :donation_amount_recommendation_remote
    create :task, account_list: account_list

    create :tag
    create :tagging, tag: ActsAsTaggableOn::Tag.last, taggable: person

    create :background_batch

    create :export_log

    create :fix_count, account_list_id: account_list.id
  end
end
