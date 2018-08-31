class Person::KeyAccount < ApplicationRecord
  include Person::Account

  validates :remote_id, :email, :person_id, presence: true
  validates :remote_id, uniqueness: true

  PERMITTED_ATTRIBUTES = [:created_at,
                          :email,
                          :first_name,
                          :last_name,
                          :overwrite,
                          :person_id,
                          :remote_id,
                          :updated_at,
                          :updated_in_db_at,
                          :id].freeze

  def self.find_or_create_from_auth(auth_hash, person)
    relation_scope   = person.key_accounts
    extra_attributes = auth_hash.extra.attributes.first
    remote_id        = extra_attributes.ssoGuid.upcase

    attributes = {
      remote_id: remote_id,
      relay_remote_id: extra_attributes.relayGuid.upcase,
      first_name: extra_attributes.firstName,
      last_name: extra_attributes.lastName,
      username: extra_attributes.email,
      email: extra_attributes.email,
      designation: extra_attributes.try(:designation),
      employee_id: extra_attributes.try(:emplid)
    }

    account = find_or_create_person_account(
      person: person,
      attributes: attributes,
      relation_scope: relation_scope
    )

    account.find_or_create_org_account if person.organization_accounts.where(organization_id: Organization.cru_usa.id).empty?

    account
  end

  def self.find_related_account(rel, attributes)
    account = rel.authenticated.find_by('upper(remote_id) = ?', attributes[:remote_id])
    account
  end

  def self.create_user_from_auth(auth_hash)
    attributes = {
      first_name: auth_hash.extra.attributes.first.firstName || 'Unknown',
      last_name: auth_hash.extra.attributes.first.lastName
    }

    super(attributes)
  end

  def self.find_authenticated_user(auth_hash)
    extra_attributes = auth_hash.extra.attributes.first
    remote_id        = extra_attributes.ssoGuid.upcase
    user_id          = authenticated.where('upper(remote_id) = ?', remote_id).pluck(:person_id).first
    User.find_by(id: user_id)
  end

  def to_s
    username
  end

  def find_or_create_org_account
    return if Rails.env.development? && ENV['DEV_SIEBEL_ORG_ACCOUNT'].blank?
    begin
      return unless SiebelDonations::Profile.find(ssoGuid: remote_id).present?
    rescue StandardError => ex
      Rollbar.raise_or_notify(ex)
      return
    end
    org = Organization.cru_usa

    # we need to create an organization account if we don't already have one
    account = person.organization_accounts.where(organization_id: org.id).first_or_initialize
    account.assign_attributes(remote_id: remote_id,
                              authenticated: true,
                              valid_credentials: true)

    account.save(validate: false)
  end
end
