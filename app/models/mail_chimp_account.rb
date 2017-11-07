require 'async'

class MailChimpAccount < ApplicationRecord
  COUNT_PER_PAGE = 100

  belongs_to :account_list
  has_one :mail_chimp_appeal_list, dependent: :destroy
  has_many :mail_chimp_members, dependent: :destroy

  attr_reader :validation_error, :gibbon_wrapper

  delegate :appeal_open_rate,
           :lists,
           :lists_available_for_newsletters_formatted,
           :lists_link,
           :primary_list,
           :primary_list_name,
           :validate_key,
           :validation_error,
           to: :gibbon_wrapper

  validates :account_list_id, :api_key, presence: true
  validates :api_key, format: /\A\w+-us\d+\z/

  serialize :tags_details, Hash
  serialize :statuses_details, Hash

  scope :that_belong_to, -> (user) { where(account_list_id: user.account_list_ids) }

  PERMITTED_ATTRIBUTES = [
    :api_key,
    :auto_log_campaigns,
    :created_at,
    :grouping_id,
    :overwrite,
    :primary_list_id,
    :sync_all_active_contacts,
    :updated_at,
    :updated_in_db_at,
    :uuid
  ].freeze

  def relevant_emails
    if sync_all_active_contacts
      active_contacts_emails
    else
      newsletter_emails
    end
  end

  def newsletter_emails
    newsletter_contacts_with_emails(nil).pluck('email_addresses.email')
  end

  def active_contacts_emails
    active_contacts_with_emails(nil).pluck('email_addresses.email')
  end

  def relevant_contacts(contact_ids = nil)
    if sync_all_active_contacts
      active_contacts_with_emails(contact_ids)
    else
      newsletter_contacts_with_emails(contact_ids)
    end
  end

  def active_contacts_with_emails(contact_ids)
    contacts_with_email_addresses(contact_ids).active
  end

  def newsletter_contacts_with_emails(contact_ids)
    contacts_with_email_addresses(contact_ids)
      .where(send_newsletter: %w(Email Both))
      .where.not(people: { optout_enewsletter: true })
  end

  def contacts_with_email_addresses(contact_ids)
    contacts = account_list.contacts
    contacts = contacts.where(id: contact_ids) if contact_ids
    contacts.joins(people: :primary_email_address)
            .where.not(email_addresses: { historic: true })
  end

  def email_hash(email)
    Digest::MD5.hexdigest(email.downcase)
  end

  def statuses_interest_ids_for_list(list_id)
    get_interest_attribute_for_list(group: :status, attribute: :interest_ids, list_id: list_id)
  end

  def tags_interest_ids_for_list(list_id)
    get_interest_attribute_for_list(group: :tag, attribute: :interest_ids, list_id: list_id)
  end

  def get_interest_attribute_for_list(group:, attribute:, list_id:)
    send("#{group.to_s.pluralize}_details")&.dig(list_id, attribute)
  end

  def set_interest_attribute_for_list(group:, attribute:, list_id:, value:)
    key = "#{group.to_s.pluralize}_details"
    hash = send(key) || {}
    hash[list_id] ||= {}
    hash[list_id][attribute] = value
    send("#{key}=", hash)
  end

  private

  def gibbon_wrapper
    @gibbon_wrapper ||= MailChimp::GibbonWrapper.new(self)
  end
end
