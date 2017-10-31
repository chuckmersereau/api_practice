require 'async'

class Organization < ApplicationRecord
  include Async # To allow batch processing of address merges
  include Sidekiq::Worker
  sidekiq_options queue: :api_organization, retry: false, unique: :until_executed

  has_many :designation_accounts, dependent: :destroy
  has_many :designation_profiles, dependent: :destroy
  has_many :donor_accounts, dependent: :destroy
  has_many :master_person_sources, dependent: :destroy
  has_many :master_people, through: :master_person_sources
  has_many :organization_accounts, class_name: 'Person::OrganizationAccount'

  validates :name, :query_ini_url, presence: true
  validates :name, uniqueness: true, case_sensitive: false
  before_create :guess_country
  before_create :guess_locale
  scope :active, -> { where('addresses_url is not null') }
  scope :using_data_server, -> { where("api_class LIKE 'DataServer%'") }

  def to_s
    name
  end

  def api(org_account)
    api_class.constantize.new(org_account)
  end

  def requires_username_and_password?
    api_class.constantize.requires_username_and_password?
  end

  def self.cru_usa
    Organization.find_by(code: 'CCC-USA')
  end

  def default_currency_code
    self[:default_currency_code] || 'USD'
  end

  def guess_country
    self.country = country_from_name
  end

  def guess_locale
    return self.locale = 'en' unless country.present?
    self.locale = ISO3166::Country.find_country_by_name(country)&.languages&.first || 'en'
  end

  # We had an organization, DiscipleMakers with a lot of duplicate addresses in its contacts and donor
  # accounts due to a difference in how their data server donor import worked and a previous iteration of
  # MPDX accepting duplicate addresses there. This will merge dup addresses in their donor accounts and
  # contacts. The merging takes a while given the large number of duplicate addressees, so it made
  # sense to run it as a single background job for the organizaton via Sidekiq/Async.
  def merge_all_dup_addresses
    # Use find_each with a small batch size to not use up memory
    donor_accounts.find_each(batch_size: 5, &:merge_addresses)

    account_lists = AccountList.joins(:users)
                               .joins('INNER JOIN person_organization_accounts ON person_organization_accounts.person_id = people.id')
                               .where(person_organization_accounts: { organization_id: id })
    account_lists.find_each(batch_size: 1) do |account_list|
      account_list.contacts.find_each(batch_size: 5, &:merge_addresses)
    end
  end

  protected

  def country_from_name
    country_name = remove_prefixes_from_name
    return 'Canada' if country_name == 'CAN'
    ::CountrySelect::COUNTRIES_FOR_SELECT.find do |country|
      country[:name] == country_name || country[:alternatives].split(' ').include?(country_name)
    end.try(:[], :name)
  end

  def remove_prefixes_from_name
    country_name = name
    ['Campus Crusade for Christ - ', 'Cru - ', 'Power To Change - ', 'Gospel For Asia', 'Agape'].each do |prefix|
      country_name = country_name.gsub(prefix, '')
    end
    country_name = country_name.split(' - ').last if country_name.include? ' - '
    country_name.strip
  end
end
