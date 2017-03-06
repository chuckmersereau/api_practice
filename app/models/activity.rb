class Activity < ApplicationRecord
  acts_as_taggable

  has_paper_trail on: [:destroy],
                  meta: { related_object_type: 'AccountList',
                          related_object_id: :account_list_id }

  belongs_to :account_list
  belongs_to :notification, inverse_of: :tasks

  has_many :activity_contacts, dependent: :destroy
  has_many :comments, dependent: :destroy, class_name: 'ActivityComment'
  has_many :contacts, through: :activity_contacts
  has_many :email_addresses, through: :people
  has_many :google_email_activities, dependent: :destroy
  has_many :google_emails, through: :google_email_activities
  has_many :google_events
  has_many :users, through: :comments
  has_many :people, through: :contacts
  has_many :phone_numbers, through: :people

  scope :completed,         -> { where(completed: true).order('completed_at desc, start_at desc') }
  scope :future,            -> { where('start_at > ?', Time.current.end_of_day).order('start_at') }
  scope :overdue,           -> { where(completed: false).where('start_at < ?', Time.current.beginning_of_day).order('start_at DESC') }
  scope :overdue_and_today, -> { where(completed: false).where('start_at < ?', Time.current.end_of_day) }
  scope :starred,           -> { where(starred: true).order('start_at') }
  scope :today,             -> { where('start_at BETWEEN ? AND ?', Time.current.beginning_of_day, Time.current.end_of_day).order('start_at') }
  scope :tomorrow,          -> { where('start_at BETWEEN ? AND ?', (Date.current + 1.day).beginning_of_day, (Date.current + 1.day).end_of_day).order('start_at') }
  scope :uncompleted,       -> { where(completed: false).order('start_at') }
  scope :upcoming,          -> { where('start_at > ?', Time.current.end_of_day + 1.day).order('start_at') }

  accepts_nested_attributes_for :activity_contacts, allow_destroy: true
  accepts_nested_attributes_for :comments, reject_if: :all_blank

  validates :subject, presence: true

  def to_s
    subject
  end

  def subject_with_contacts
    "#{contacts.map(&:to_s).join(', ')} - #{_(activity_type)}: #{subject}"
  end

  def contacts_attributes=(contacts_array)
    contacts_array = contacts_array.values if contacts_array.is_a?(Hash)
    contacts_array.each do |contact_attributes|
      contact = Contact.find(contact_attributes['id'])
      if contact_attributes['_destroy'].to_s == 'true'
        contacts.delete(contact) if contacts.include?(contact)
      else
        contacts << contact unless contacts.include?(contact)
      end
    end
  end

  def activity_contacts_attributes=(hash_or_array)
    contacts_array = hash_or_array.is_a?(Hash) ? hash_or_array.values : hash_or_array
    contacts_array.each do |contact_attributes|
      next unless contact_attributes['contact_id'].present?

      contact = Contact.find(contact_attributes['contact_id'])
      if contact_attributes['_destroy'].to_s == 'true'
        contacts.delete(contact) if contacts.include?(contact)
      else
        contacts << contact unless contacts.include?(contact)
      end
    end
  end

  def activity_comment=(hash)
    comments.new(hash) if hash.values.any?(&:present?)
  end

  def assignable_contacts
    assigned_contact_ids = activity_contacts.pluck(:contact_id)
    return account_list.active_contacts if assigned_contact_ids.empty?

    account_list.contacts
                .where(Contact.active_conditions + ' OR contacts.id IN (?)', assigned_contact_ids)
  end
end
