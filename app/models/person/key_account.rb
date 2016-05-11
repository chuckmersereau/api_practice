class Person::KeyAccount < ActiveRecord::Base
  include Person::Account

  self.table_name = 'person_relay_accounts'

  def self.find_or_create_from_auth(auth_hash, user)
    @rel = user.key_accounts
    extra_attributes = auth_hash.extra.attributes.first
    @remote_id = extra_attributes.ssoGuid.upcase
    @attributes = {
      remote_id: @remote_id,
      relay_remote_id: extra_attributes.relayGuid.upcase,
      first_name: extra_attributes.firstName,
      last_name: extra_attributes.lastName,
      username: extra_attributes.email,
      email: extra_attributes.email,
      designation: extra_attributes.try(:designation),
      employee_id: extra_attributes.try(:emplid)
    }

    account = super
    if user.organization_accounts.where(organization_id: Organization.cru_usa.id).empty?
      account.find_or_create_org_account
    end
    account
  end

  def self.find_related_account(rel, remote_id)
    account = rel.authenticated.find_by('upper(remote_id) = ?', remote_id)
    if @attributes && @attributes[:relay_remote_id]
      # see comment inside self.find_authenticated_user
      account ||= rel.authenticated.find_by('upper(relay_remote_id) = ?', @attributes[:relay_remote_id].upcase)
    end
    account
  end

  def self.create_user_from_auth(auth_hash)
    @attributes = {
      first_name: auth_hash.extra.attributes.first.firstName || 'Unknown',
      last_name: auth_hash.extra.attributes.first.lastName
    }

    super
  end

  def self.find_authenticated_user(auth_hash)
    extra_attributes = auth_hash.extra.attributes.first
    key_guid = extra_attributes.ssoGuid.upcase
    relay_guid = extra_attributes.relayGuid&.upcase
    user_id = authenticated.where('upper(remote_id) = ?', key_guid).pluck(:person_id).first

    # this is a fall back to cover the time while remote_id's are nil between when they are moved to
    # relay_remote_id's and when dev/migrate/2016_03_31_merge_key_relay.rb is run. During that time
    # remote_id will be nil
    user_id ||= authenticated.where('upper(relay_remote_id) = ?', relay_guid).pluck(:person_id).first
    User.find_by(id: user_id)
  end

  def to_s
    username
  end

  def find_or_create_org_account
    return if Rails.env.development?
    return unless SiebelDonations::Profile.find(ssoGuid: relay_remote_id).present?
    org = Organization.cru_usa

    # we need to create an organization account if we don't already have one
    account = person.organization_accounts.where(organization_id: org.id).first_or_initialize
    account.assign_attributes(remote_id: remote_id,
                              authenticated: true,
                              valid_credentials: true)
    account.save(validate: false)
  end
end
