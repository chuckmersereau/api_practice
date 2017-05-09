class Person::TwitterAccount < ApplicationRecord
  include Person::Account
  after_save :ensure_only_one_primary

  PERMITTED_ATTRIBUTES = [:created_at,
                          :overwrite,
                          :primary,
                          :remote_id,
                          :screen_name,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze

  validates :screen_name, presence: true

  # attr_accessible :screen_name

  def self.find_or_create_from_auth(auth_hash, person)
    relation_scope = person.twitter_accounts
    params         = auth_hash.extra.access_token.params
    primary        = person.twitter_accounts.present? ? false : true

    attributes = {
      remote_id: params[:screen_name],
      screen_name: params[:screen_name],
      token: params[:oauth_token],
      secret: params[:oauth_token_secret],
      valid_token: true,
      primary: primary
    }

    find_or_create_person_account(
      person: person,
      attributes: attributes,
      relation_scope: relation_scope
    )
  end

  def to_s
    screen_name
  end

  def self.one_per_user?
    false
  end

  def queue_import_data
  end

  def url
    "http://twitter.com/#{screen_name}" if screen_name
  end

  private

  def ensure_only_one_primary
    primaries = person.twitter_accounts.where(primary: true)
    primaries[0..-2].map { |p| p.update_column(:primary, false) } if primaries.length > 1
  end
end
