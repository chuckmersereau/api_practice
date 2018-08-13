require 'factory_bot'

class ApplicationSeeder
  ALLOWED_ENV = %w(test development).freeze
  LOCAL = %w(localhost 127.0.0.1).freeze

  attr_accessor :quiet

  def initialize(quiet = !Rails.env.development?)
    self.quiet = quiet
  end

  def seed
    safe!
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
    unseeded.each { |record_class| Rails.logger.info "Warning: No records seeded for class #{record_class}" } unless quiet
    unseeded.blank?
  end

  private

  def safe!
    raise "Turn Back! ApplicationSeeder is not permitted in #{Rails.env}" unless ALLOWED_ENV.include?(Rails.env)

    db_host = Rails.configuration.database_configuration[Rails.env]['host']
    raise 'ApplicationSeeder is not permitted connected to a remote host' unless LOCAL.include?(db_host)
  end

  def intro
    return if quiet
    Rails.logger.info '== Starting database seeding... ==============================================='
    Rails.logger.info "The database will be seeded using FactoryBot factories.\nPrinting the name of each factory as it's created:"
  end

  def outro
    return if quiet
    Rails.logger.info "\n== Finished database seeding! ================================================="
  end

  def create(*args)
    Rails.logger.info "#{args.first}... " unless quiet
    FactoryBot.create(*args)
  end

  def seed_all_models
    # Seed NotificationTypes separately:
    NotificationTypesSeeder.new(quiet).seed

    Rails.application.eager_load!
    ApplicationRecord.descendants.each(&:reset_column_information)

    # Create some fundamental records first so that we can reference them below to establish associations:

    organization = create :organization
    user = create :user_with_full_account
    account_list = user.account_lists.reload.order(:created_at).last
    contact = create :contact, account_list: account_list
    master_person = create :master_person
    person = create :person, master_person: master_person
    contact.people << person

    create :contact_referral, referred_by: contact, referred_to: create(:contact)
    create :contact_notes_log, contact: contact

    create :account_list_invite, account_list: account_list
    create :account_list_coach, account_list: account_list, coach: user.becomes(User::Coach)

    activity = create :activity, account_list: account_list
    create :activity_comment, activity: activity, person: person
    create :activity_contact, activity: activity, contact: contact

    create :address, addressable: contact

    create :admin_impersonation_log, impersonator: user, impersonated: create(:user)
    create :admin_reset_log

    appeal = create(:appeal, account_list: account_list)
    create :appeal_contact, appeal: appeal, contact: contact
    create :appeal_excluded_appeal_contact, appeal: appeal, contact: contact

    company = create :company
    create :company_partnership, company: company, account_list: account_list
    create :company_position, company: company, person: person

    create(:currency_alias) unless CurrencyAlias.any?
    create(:currency_rate) unless CurrencyRate.any?

    donor_account = create :donor_account, organization: organization
    create :contact_donor_account, contact: contact, donor_account: donor_account
    create :donor_account_person, donor_account: donor_account, person: person

    designation_account = create :designation_account, organization: organization
    create :designation_profile_account,
           designation_profile: DesignationProfile.order(:created_at).last,
           designation_account: designation_account

    create :duplicate_contacts_pair, account_list: account_list
    create :duplicate_people_pair, account_list: account_list

    donation = create :donation,
                      donor_account: donor_account,
                      designation_account: designation_account
    pledge = create :pledge, account_list: account_list, contact: contact
    create :pledge_donation, pledge: pledge, donation: donation

    create :phone_number, person: person

    email_address = create :email_address, person: person
    create :google_plus_account, email_address: email_address

    create :event, account_list: account_list

    create :family_relationship, person: person, related_person: create(:person)

    google_account = create :google_account, person: person
    create :google_contact, person: person
    google_email = create :google_email, google_account: google_account
    create :google_email_activity,
           google_email: google_email,
           activity: create(:activity, account_list: account_list)
    google_integration = create :google_integration,
                                account_list: account_list,
                                google_account: google_account,
                                calendar_integration: false
    create :google_event,
           activity: create(:activity, account_list: account_list),
           google_integration: google_integration

    create :help_request, account_list: account_list

    create :import, account_list: account_list

    mail_chimp_account = create :mail_chimp_account, account_list: account_list
    create :mail_chimp_appeal_list,
           mail_chimp_account: mail_chimp_account,
           appeal: appeal
    create :mail_chimp_member, mail_chimp_account: mail_chimp_account

    create :master_address
    create :master_company
    create :master_person_donor_account,
           master_person: master_person,
           donor_account: donor_account
    create :master_person_source, master_person: master_person, organization: organization

    create :message, account_list: account_list
    create :name_male_ratio
    create :nickname

    create :notification_preference,
           notification_type: NotificationType.order(:created_at).last,
           account_list: account_list
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
    task = create :task, account_list: account_list

    tag = create :tag
    create :tagging, tag: tag, taggable: contact
    create :tagging, tag: tag, taggable: task

    create :background_batch

    create :export_log
    create :deleted_record
  end
end
