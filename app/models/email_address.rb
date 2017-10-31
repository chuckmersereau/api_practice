class EmailAddress < ApplicationRecord
  include Concerns::AfterValidationSetSourceToMPDX
  include HasPrimary
  @@primary_scope = :person

  PERMITTED_ATTRIBUTES = [:created_at,
                          :email,
                          :historic,
                          :location,
                          :overwrite,
                          :primary,
                          :source,
                          :updated_at,
                          :updated_in_db_at,
                          :uuid,
                          :valid_values].freeze

  belongs_to :person, touch: true
  has_one :google_plus_account

  before_save :strip_email_attribute, :check_state_for_mail_chimp_sync
  before_create :set_valid_values
  after_save :trigger_mail_chimp_syncs_to_relevant_contacts, if: :sync_with_mail_chimp_required?
  after_create :start_google_plus_account_fetcher_job, unless: :checked_for_google_plus_account

  validates :email, presence: true, email: true, uniqueness: { scope: :person_id }
  validates :email, :remote_id, :location, updatable_only_when_source_is_mpdx: true

  global_registry_bindings parent: :person,
                           fields: { email: :email, primary: :boolean }

  def to_s
    email
  end

  def self.add_for_person(person, attributes)
    attributes = attributes.with_indifferent_access.except(:_destroy)
    then_cb = proc do |_exception, _handler, _attempts, _retries, _times|
      person.email_addresses.reload
    end

    attributes['email'] = strip_email(attributes['email'].to_s)

    email = Retryable.retryable on: ActiveRecord::RecordNotUnique,
                                then: then_cb do
      if attributes['id']
        existing_email = person.email_addresses.find(attributes['id'])
        email = person.email_addresses.find { |e| e.email == attributes['email'] && e.id != attributes['id'].to_i }
        # make sure we're not updating this record to another email that already exists
        if email
          email.attributes = attributes
          existing_email.destroy
          email
        else
          existing_email.attributes = attributes
          existing_email
        end
      else
        email = person.email_addresses.find { |e| e.email == attributes['email'] }
        if email
          email.attributes = attributes
        else
          attributes['primary'] ||= !person.email_addresses.present?
          new_or_create = person.new_record? ? :new : :create
          email = person.email_addresses.send(new_or_create, attributes)
        end
        email
      end
    end
    email.save unless email.new_record?
    email
  end

  def self.expand_and_clean_emails(email_attrs)
    cleaned_attrs = []
    clean_and_split_emails(email_attrs[:email]).each_with_index do |cleaned_email, index|
      cleaned = email_attrs.dup
      cleaned[:primary] = false if index.positive? && email_attrs[:primary]
      cleaned[:email] = cleaned_email
      cleaned_attrs << cleaned
    end
    cleaned_attrs
  end

  def self.clean_and_split_emails(emails_str)
    return [] if emails_str.blank?

    emails_str.scan(/([^<>,;\s]+@[^<>,;\s]+)/).map(&:first)
  end

  def self.strip_email(email)
    # Some email addresses seem to get zero-width characters like the
    # zero-width-space (\u200B) or left-to-right mark (\u200E)
    email.to_s.gsub(/[\u200B-\u200F]/, '').strip
  end

  private

  def trigger_mail_chimp_syncs_to_relevant_contacts
    person.contacts.each(&:sync_with_mail_chimp)
  end

  def sync_with_mail_chimp_required?
    @mail_chimp_sync
  end

  def check_state_for_mail_chimp_sync
    @mail_chimp_sync = true if should_trigger_mail_chimp_sync?
  end

  def should_trigger_mail_chimp_sync?
    primary? && (email_changed? || !persisted?)
  end

  def start_google_plus_account_fetcher_job
    GooglePlusAccountFetcherWorker.perform_async(id)
  end

  def strip_email_attribute
    self.email = self.class.strip_email(email)
  end

  def contact
    @contact ||= person.try(:contacts).try(:first)
  end

  def set_valid_values
    self.valid_values = (source == MANUAL_SOURCE) || !self.class.where(person: person).exists?
    true
  end
end
