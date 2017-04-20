class Appeal < ApplicationRecord
  belongs_to :account_list
  has_one :mail_chimp_account, through: :account_list
  has_many :appeal_contacts
  has_many :contacts, through: :appeal_contacts
  has_many :excluded_appeal_contacts, dependent: :delete_all
  has_many :donations

  validates :name, :account_list_id, presence: true

  default_scope { order(created_at: :desc) }

  scope :that_belong_to, -> (user) { where(account_list_id: user.account_list_ids) }

  PERMITTED_ATTRIBUTES = [:account_list_id,
                          :amount,
                          :created_at,
                          :description,
                          :end_date,
                          :name,
                          :overwrite,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid].freeze

  def selected_contacts(excluded)
    excluded == 1 ? excluded_appeal_contacts : contacts
  end

  def add_and_remove_contacts(account_list, contact_ids)
    contact_ids ||= []

    valid_contact_ids = account_list.contacts.pluck(:id) & contact_ids
    new_contact_ids = valid_contact_ids - contacts.pluck(:id)
    new_contact_ids.each do |contact_id|
      return false unless AppealContact.new(appeal_id: id, contact_id: contact_id).save
    end

    contact_ids_to_remove = contacts.pluck(:id) - contact_ids
    contact_ids_to_remove.each do |contact_id|
      contacts.delete(contact_id)
    end
  end

  def add_contacts_by_opts(statuses, tags, excludes)
    bulk_add_contacts(contacts: contacts_by_opts(statuses, tags, excludes))
  end

  def bulk_add_contacts(contacts: [], contact_ids: contacts.map(&:id))
    appeal_contact_ids = self.contact_ids
    contact_ids_to_add = contact_ids.uniq - appeal_contact_ids

    appeal_contacts_to_import = contact_ids_to_add.map do |contact_id|
      AppealContact.new(contact_id: contact_id, appeal: self)
    end

    AppealContact.import(appeal_contacts_to_import)
  end

  def contacts_by_opts(statuses, tags, excludes)
    excluder = AppealContactsExcluder.new(appeal: self)
    excluder.excludes_scopes(account_list.contacts
      .joins("LEFT JOIN taggings ON taggings.taggable_type = 'Contact' AND taggings.taggable_id = contacts.id")
      .joins('LEFT JOIN tags ON tags.id = taggings.tag_id')
      .distinct
      .where(statuses_and_tags_where(statuses, tags)), excludes)
  end

  def statuses_and_tags_where(statuses, tags)
    if statuses.nil? || statuses.empty?
      tags.nil? || tags.empty? ? '1=0' : "tags.name IN (#{quote_sql_list(tags)})"
    elsif tags.nil? || tags.empty?
      "contacts.status IN (#{quote_sql_list(statuses)})"
    else
      "contacts.status IN (#{quote_sql_list(statuses)}) OR tags.name IN (#{quote_sql_list(tags)})"
    end
  end

  def quote_sql_list(list)
    list.map { |item| ActiveRecord::Base.connection.quote(item) }.join(',')
  end

  def donated?(contact)
    donations.joins(donor_account: :contact_donor_accounts).exists?(contact_donor_accounts: { contact_id: contact.id })
  end
end
