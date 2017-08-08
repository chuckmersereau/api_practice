require 'signet/oauth_2/client'

class Person::GoogleAccount < ApplicationRecord
  include Person::Account

  has_many :google_integrations, foreign_key: :google_account_id, dependent: :destroy
  has_many :google_emails,       foreign_key: :google_account_id
  has_many :google_contacts,     foreign_key: :google_account_id

  PERMITTED_ATTRIBUTES = [:created_at,
                          :email,
                          :overwrite,
                          :person_id,
                          :primary,
                          :remote_id,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze

  def self.find_or_create_from_auth(auth_hash, person)
    Rails.logger.debug(auth_hash)

    relation_scope = person.google_accounts
    creds          = auth_hash.credentials
    remote_id      = auth_hash.uid
    expires_at     = creds.expires ? Time.at(creds.expires_at) : nil

    attributes = {
      remote_id: remote_id,
      token: creds.token,
      refresh_token: creds.refresh_token,
      expires_at: expires_at,
      email: auth_hash.info.email,
      valid_token: true
    }

    find_or_create_person_account(
      person: person,
      attributes: attributes,
      relation_scope: relation_scope
    )
  end

  def self.create_user_from_auth(_auth_hash)
    raise Person::Account::NoSessionError, 'Somehow a user without an account/session is trying to sign in using google'
  end

  def google_integration(account_list_id)
    google_integrations.find_by(account_list_id: account_list_id)
  end

  def to_s
    email
  end

  def self.one_per_user?
    false
  end

  def token_expired?
    (expires_at || Time.current) <= Time.current
  end

  def token_failure?
    notified_failure == true
  end

  def contacts
    @contacts ||= contacts_api_user.contacts
  end

  def contact_groups
    @contact_groups ||= Person::GoogleAccount::ContactGroup.from_groups(contacts_api_user.groups)
  rescue Person::GoogleAccount::MissingRefreshToken
    []
  end

  def contacts_for_group(group_id)
    GoogleContactsApi::Group.new({ 'id' => { '$t' => group_id } }, nil, contacts_api_user.api).contacts
  end

  def contacts_api_user
    raise Person::GoogleAccount::MissingRefreshToken if token_expired? && !refresh_token!

    unless @contact_api_user
      client = OAuth2::Client.new(ENV.fetch('GOOGLE_KEY'), ENV.fetch('GOOGLE_SECRET'))
      oath_token = OAuth2::AccessToken.new(client, token)
      @contact_api_user = GoogleContactsApi::User.new(oath_token)
    end
    @contact_api_user
  end

  def authorization
    return false if token_expired? && !refresh_token!
    @authorization ||= Signet::OAuth2::Client.new(authorization_uri: 'https://accounts.google.com/o/oauth2/auth',
                                                  token_credential_uri: 'https://www.googleapis.com/oauth2/v3/token',
                                                  client_id: ENV.fetch('GOOGLE_KEY'),
                                                  client_secret: ENV.fetch('GOOGLE_SECRET'),
                                                  access_token: token,
                                                  refresh_token: refresh_token)
  end

  def refresh_token!
    if refresh_token.blank?
      needs_refresh
      return false
    end

    # Refresh auth token from google_oauth2.
    params = {
      client_id: ENV.fetch('GOOGLE_KEY'),
      client_secret: ENV.fetch('GOOGLE_SECRET'),
      refresh_token: refresh_token,
      grant_type: 'refresh_token'
    }
    RestClient.post('https://accounts.google.com/o/oauth2/token', params, content_type: 'application/x-www-form-urlencoded') do |response, _request, _result, &_block|
      json = JSON.parse(response)
      if response.code == 200
        self.token = json['access_token']
        self.expires_at = 59.minutes.from_now
        self.notified_failure = false
        save
      else
        case json['error']
        when 'invalid_grant', 'invalid_client'
          needs_refresh
        else
          Rollbar.error(response.inspect)
        end
        return false
      end
    end
  end

  def needs_refresh
    google_integrations.each do |integration|
      integration.update_columns(calendar_integration: false, email_integration: false,
                                 contacts_integration: false) # no callbacks
      AccountMailer.delay.google_account_refresh(person, integration) unless notified_failure
      update(notified_failure: true)
    end
  end

  class MissingRefreshToken < StandardError
  end
end
