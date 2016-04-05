require 'async'
require 'retryable'

class Person::FacebookAccount < ActiveRecord::Base
  include Person::Account
  include Redis::Objects
  include Async
  include Sidekiq::Worker
  sidekiq_options queue: :facebook, unique: true

  set :friends
  # attr_accessible :remote_id, :token, :token_expires_at, :first_name, :last_name, :valid_token, :authenticated, :url

  def self.find_or_create_from_auth(auth_hash, person)
    @rel = person.facebook_accounts
    @remote_id = auth_hash['uid']
    @attributes = {
      remote_id: @remote_id,
      token: auth_hash.credentials.token,
      token_expires_at: Time.at(auth_hash.credentials.expires_at),
      first_name: auth_hash.info.first_name,
      last_name: auth_hash.info.last_name,
      valid_token: true
    }
    super
  end

  def self.create_user_from_auth(auth_hash)
    @attributes = {
      first_name: auth_hash.info.first_name,
      last_name: auth_hash.info.last_name
    }

    super
  end

  def to_s
    [first_name, last_name].join(' ')
  end

  def url
    prefix = 'https://www.facebook.com/'
    return prefix + "profile.php?id=#{remote_id}" if remote_id.to_i > 0
    prefix + username if username
  end

  def url=(value)
    return unless value.present?
    self.remote_id = self.class.id_from_url(value)
    self.username = self.class.username_from_url(value) unless remote_id
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
    if tries == 0 && token && (!token_expires_at || token_expires_at < Time.now)
      begin
        refresh_token
      rescue; end
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
    rescue => e
      raise e.message + ': ' + info.inspect
    end
    save
  end

  # Refresh any tokens that will be expiring soon
  def self.refresh_tokens
    Person::FacebookAccount.where('token_expires_at < ? AND token_expires_at > ?', 2.days.from_now, Time.now).find_each(&:refresh_token)
  end

  def self.search(user, params)
    if account = user.facebook_accounts.first
      FbGraph::User.search(params.slice(:first_name, :last_name).values.join(' '), access_token: account.token)
    else
      []
    end
  end

  private

  def import_contacts(import_id)
    import = Import.find(import_id)
    FacebookImport.new(self, import).import_contacts
  ensure
    update_column(:downloading, false)
  end
end
