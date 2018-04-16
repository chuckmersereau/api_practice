class EmailAddress < ApplicationRecord
  include Concerns::AfterValidationSetSourceToMPDX
  include HasPrimary
  @@primary_scope = :person

  audited associated_with: :person, except: [:updated_at, :global_registry_id, :checked_for_google_plus_account]

  PERMITTED_ATTRIBUTES = [:created_at,
                          :email,
                          :historic,
                          :location,
                          :overwrite,
                          :primary,
                          :source,
                          :updated_at,
                          :updated_in_db_at,
                          :id,
                          :valid_values].freeze

  belongs_to :person, touch: true
  has_one :google_plus_account

  before_save :strip_email_attribute, :check_state_for_mail_chimp_sync
  before_create :set_valid_values
  after_save :trigger_mail_chimp_syncs_to_relevant_contacts, if: :sync_with_mail_chimp_required?
  after_create :start_google_plus_account_fetcher_job, unless: :checked_for_google_plus_account
  validates :email, presence: true, email: true, uniqueness: { scope: [:person_id, :source], case_sensitive: false }
  validates :email, :remote_id, :location, updatable_only_when_source_is_mpdx: true

  global_registry_bindings parent: :person,
                           fields: { email: :email, primary: :boolean }

  def to_s
    email
  end

  def email=(email)
    super(email&.downcase)
  end

  class << self
    def add_for_person(person, attributes)
      attributes = attributes.with_indifferent_access.except(:_destroy)
      then_cb = proc do |_exception, _handler, _attempts, _retries, _times|
        person.email_addresses.reload
      end

      attributes['email'] = strip_email(attributes['email'].to_s).downcase

      email = Retryable.retryable on: ActiveRecord::RecordNotUnique,
                                  then: then_cb do
        if attributes['id']
          replace_existing_email(person, attributes)
        else
          create_or_update_email(person, attributes)
        end
      end
      email.save unless email.new_record?
      email
    end

    def expand_and_clean_emails(email_attrs)
      cleaned_attrs = []
      clean_and_split_emails(email_attrs[:email]).each_with_index do |cleaned_email, index|
        cleaned = email_attrs.dup
        cleaned[:primary] = false if index.positive? && email_attrs[:primary]
        cleaned[:email] = cleaned_email
        cleaned_attrs << cleaned
      end
      cleaned_attrs
    end

    def clean_and_split_emails(emails_str)
      return [] if emails_str.blank?

      emails_str.scan(/([^<>,;\s]+@[^<>,;\s]+)/).map(&:first)
    end

    def strip_email(email)
      # Some email addresses seem to get zero-width characters like the
      # zero-width-space (\u200B) or left-to-right mark (\u200E)
      email.to_s.gsub(/\p{Z}|\p{C}/, '')
    end

    private

    def replace_existing_email(person, attributes)
      existing_email = person.email_addresses.find(attributes['id'])
      email = person.email_addresses.find { |e| e.email == attributes['email'] && e.id != attributes['id'] }

      # make sure we're not updating this record to another email that already exists
      if email
        email.attributes = attributes
        existing_email.destroy
        email
      else
        existing_email.attributes = attributes
        existing_email
      end
    end

    def create_or_update_email(person, attributes)
      email = person.email_addresses.find { |e| e.email == attributes['email'] }

      if both_from_tnt_sources?(email, attributes)
        email.attributes = attributes
      else
        attributes['primary'] ||= person.email_addresses.empty?
        new_or_create = person.new_record? ? :new : :create
        email = person.email_addresses.send(new_or_create, attributes)
      end
      email
    end

    def both_from_tnt_sources?(email, attrs)
      email && (attrs[:source] != TntImport::SOURCE || email.source == attrs[:source])
    end
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
    primary? && (primary_changed? || email_changed? || !persisted?)
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
