require_dependency 'data_server'
require_dependency 'credential_validator'
require 'async'

class Person::OrganizationAccount < ApplicationRecord
  include Person::Account
  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :api_person_organization_account, retry: false, unique: :until_executed

  serialize :password, Encryptor.new

  after_create :set_up_account_list, :queue_import_data
  validates :organization_id, :person_id, presence: true
  validates :username, :password, presence: { if: :requires_username_and_password? }
  validates_with CredentialValidator
  after_validation :set_valid_credentials
  after_destroy :destroy_designation_profiles
  belongs_to :organization

  PERMITTED_ATTRIBUTES = [:created_at,
                          :organization_id,
                          :overwrite,
                          :password,
                          :person_id,
                          :updated_at,
                          :updated_in_db_at,
                          :username,
                          :uuid].freeze

  def to_s
    str = organization.to_s
    employee_id = user.relay_accounts.where(remote_id: remote_id).pluck(:employee_id).first
    postfix = username || employee_id || remote_id
    str += ': ' + postfix if postfix
    str
  end

  def user
    @user ||= person.to_user
  end

  def self.one_per_user?
    false
  end

  def self.clear_stalled_downloads
    where('locked_at is not null and locked_at < ?', 2.days.ago).update_all(downloading: false, locked_at: nil)
  end

  def requires_username_and_password?
    organization.api(self).requires_username_and_password? if organization
  end

  def queue_import_data
    async(:import_all_data)
  end

  def account_list
    user.designation_profiles.first.try(:account_list)
  end

  def designation_profiles
    DesignationProfile.where(organization_id: organization_id, user_id: person_id)
  end

  def import_all_data
    return if locked_at || new_record? || !valid_rechecked_credentials
    update_column(:downloading, true)
    import_donations
  rescue OrgAccountInvalidCredentialsError, OrgAccountMissingCredentialsError
    update_column(:valid_credentials, false)
    ImportMailer.delay.credentials_error(self)
  ensure
    clear_lock_fields
  end

  def import_profiles
    organization.api(self).import_profiles
  rescue DataServerError => e
    Rollbar.error(e)
  end

  private

  def valid_rechecked_credentials
    # Trigger validation to check if the credentials are actually valid in case
    # they were previously incorrectly indicated by a data server as invalid.
    valid_credentials || valid?
  end

  def import_donations
    starting_time = Time.current
    starting_donation_count = user.donations.count
    import_donations_from_api

    # we only want to set the last_download date if at least one donation was downloaded
    return unless user.donations.count > starting_donation_count
    process_new_donations_downloaded(import_started_at: starting_time)
  end

  def import_donations_from_api
    update(downloading: true, locked_at: Time.now)
    date_from = last_download ? (last_download - 50.days) : ''
    organization.api(self).import_all(date_from)
  end

  def process_new_donations_downloaded(import_started_at:)
    ContactSuggestedChangesUpdaterWorker.perform_async(user.id, import_started_at)

    # Set the last download date to whenever the last donation was received
    last_donation_date = user.donations
                             .where.not(remote_id: nil).order('donation_date desc').first.donation_date
    update_column(:last_download, last_donation_date)
  end

  def clear_lock_fields
    update_columns(downloading: false, locked_at: nil)
  rescue ActiveRecord::ActiveRecordError
  end

  def set_valid_credentials
    self.valid_credentials = true
  end

  # The purpose of this method is to transparently share one account list between two spouses.
  # In general any time two people have access to a designation profile containing only one
  # designation account, the second person will be given access to the first person's account list
  def set_up_account_list
    import_profiles

    # If this org account doesn't have any profiles, create a default account list and profile for them
    if user.account_lists.reload.empty? || organization.designation_profiles.where(user_id: person_id).blank?
      account_list = user.account_lists.create!(name: user.to_s, creator_id: user.id)
      organization.designation_profiles.create!(name: user.to_s, user_id: user.id, account_list_id: account_list.id)
    end
  end

  def destroy_designation_profiles
    designation_profiles.destroy_all
  end
end
