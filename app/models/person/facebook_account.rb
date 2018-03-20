require 'async'
require 'retryable'

class Person::FacebookAccount < ApplicationRecord
  include Person::Account
  include Redis::Objects
  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :api_person_facebook_account, unique: :until_executed

  PERMITTED_ATTRIBUTES = [:created_at,
                          :first_name,
                          :last_name,
                          :overwrite,
                          :remote_id,
                          :updated_at,
                          :updated_in_db_at,
                          :username,
                          :id].freeze

  validates :username, presence: true, uniqueness: { scope: :person_id }

  def self.find_or_create_from_auth(auth_hash, person)
    relation_scope = person.facebook_accounts
    remote_id      = auth_hash['uid']

    attributes = {
      remote_id: remote_id,
      token: auth_hash.credentials.token,
      token_expires_at: Time.at(auth_hash.credentials.expires_at),
      first_name: auth_hash.info.first_name,
      last_name: auth_hash.info.last_name,
      valid_token: true,
      username: remote_id
    }

    find_or_create_person_account(
      person: person,
      attributes: attributes,
      relation_scope: relation_scope
    )
  end

  def self.create_user_from_auth(auth_hash)
    attributes = {
      first_name: auth_hash.info.first_name,
      last_name: auth_hash.info.last_name
    }

    super(attributes)
  end

  def to_s
    [first_name, last_name].join(' ')
  end

  def url
    prefix = 'https://www.facebook.com/'
    return prefix + "profile.php?id=#{remote_id}" if remote_id.to_i.positive?
    prefix + username if username
  end

  def url=(value)
    return unless value.present?
    self.remote_id = self.class.id_from_url(value)
    self.username = self.class.username_from_url(value) unless remote_id
  end

  def username=(value)
    new_remote_id = self.class.id_from_url(value)
    self.remote_id = new_remote_id if new_remote_id
    super(self.class.username_from_url(value) || value)
  end

  def self.id_from_url(url)
    return unless url.present? && url.include?('id=')
    url.split('id=').last.split('&').first
  end

  def self.username_from_url(url)
    return unless url.present? && url.include?('facebook.com/')
    url.split('/').last.split('&').first
  end

  def queue_import_contacts(import)
    async(:import_contacts, import.id)
  end

  def token_missing_or_expired?(tries = 0)
    # If we have an expired token, try once to refresh it
    if tries.zero? && token && (!token_expires_at || token_expires_at < Time.now)
      begin
        refresh_token
      rescue StandardError; end
      token_missing_or_expired?(1)
    else
      token.blank? || !token_expires_at || token_expires_at < Time.now
    end
  end

  def refresh_token
    info = Koala::Facebook::OAuth.new(ENV.fetch('FACEBOOK_KEY'), ENV.fetch('FACEBOOK_SECRET')).exchange_access_token_info(token)
    self.token = info['access_token']
    begin
      self.token_expires_at = Time.at(info['expires'].to_i)
    rescue StandardError => e
      raise e.message + ': ' + info.inspect
    end
    save
  end

  def self.search(user, params)
    account = user.facebook_accounts.first
    return [] unless account
    FbGraph::User.search(params.slice(:first_name, :last_name).values.join(' '), access_token: account.token)
  end

  private

  def import_contacts(import_id)
    import = Import.find(import_id)
    FacebookImport.new(self, import).import_contacts
  ensure
    update_column(:downloading, false)
  end
end
