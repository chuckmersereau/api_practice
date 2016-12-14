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
    unseeded = ActiveRecord::Base.descendants.reject(&:abstract_class?).reject(&:exists?)
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

    # Create some fundamental records first so that we can reference them below to establish associations:
    organization = create :organization
    user = create :user_with_full_account
    account_list = user.account_lists.last
    contact = create :contact_with_person, account_list: account_list
    person = contact.people.last

    create :contact_referral, referred_by: contact, referred_to: create(:contact)
    create :contact_notes_log, contact: contact

    create :account_list_invite

    create :activity, account_list: account_list
    create :activity_comment, activity: Activity.last, person: person
    create :activity_contact, activity: Activity.last, contact: contact

    create :address, addressable: person

    create :admin_impersonation_log, impersonator: user, impersonated: create(:user)
    create :admin_reset_log

    create :appeal, account_list: account_list
    create :appeal_contact, appeal: Appeal.last, contact: contact
    create :appeal_excluded_appeal_contact, appeal: Appeal.last, contact: contact

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

    create :donation, donor_account: DonorAccount.last, designation_account: DesignationAccount.last

    create :phone_number, person: person
    create :email_address
    create :event

    create :family_relationship, person: person, related_person: create(:person)

    create :google_account, person: person
    create :google_contact
    create :google_email, google_account: Person::GoogleAccount.last
    create :google_email_activity, google_email: GoogleEmail.last, activity: create(:activity)
    create :google_integration, account_list: account_list, google_account: Person::GoogleAccount.last, calendar_integration: false
    create :google_event, activity: create(:activity), google_integration: GoogleIntegration.last

    create :help_request

    create :import

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
    create :notification

    create :partner_status_log, contact: contact

    create :facebook_account, person: person
    create :key_account, person: person
    create :linkedin_account, person: person
    create :relay_account, person: person
    create :twitter_account, person: person
    create :website, person: person

    create :picture, picture_of: person
    create :pls_account
    create :prayer_letters_account, account_list: account_list
    create :recurring_recommendation_result
    create :task, account_list: account_list

    create :tag
    create :tagging, tag: ActsAsTaggableOn::Tag.last, taggable: person

    create :version, item_id: contact.id, item_type: contact.class.to_s, related_object_id: person.id, related_object_type: person.class.to_s
  end
end
