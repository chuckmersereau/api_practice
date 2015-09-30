class EmailAddress < ActiveRecord::Base
  include HasPrimary
  @@primary_scope = :person

  has_paper_trail on: [:destroy],
                  meta: { related_object_type: 'Person',
                          related_object_id: :person_id }

  belongs_to :person, touch: true
  validates :email, presence: true, email: true, uniqueness: { scope: :person_id }
  before_save :strip_email

  def to_s
    email
  end

  def self.add_for_person(person, attributes)
    attributes = attributes.with_indifferent_access.except(:_destroy)
    then_cb = proc do |_exception, _handler, _attempts, _retries, _times|
      person.email_addresses.reload
    end

    email = Retryable.retryable on: ActiveRecord::RecordNotUnique,
                                then: then_cb do
      if attributes['id']
        existing_email = person.email_addresses.find(attributes['id'])
        # make sure we're not updating this record to another email that already exists
        if email = person.email_addresses.find { |e| e.email == attributes['email'].to_s.strip && e.id != attributes['id'].to_i }
          email.attributes = attributes
          existing_email.destroy
          email
        else
          existing_email.attributes = attributes
          existing_email
        end
      else
        if email = person.email_addresses.find { |e| e.email == attributes['email'].to_s.strip }
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
      cleaned[:primary] = false if index > 0 && email_attrs[:primary]
      cleaned[:email] = cleaned_email
      cleaned_attrs << cleaned
    end
    cleaned_attrs
  end

  def self.clean_and_split_emails(emails_str)
    return [] if emails_str.blank?
    emails_str.scan(/([^<>,;\s]+@[^<>,;\s]+)/).map(&:first)
  end

  private

  def strip_email
    # Some email addresses seem to get zero-width characters like the
    # zero-width-space (\u200B) or left-to-right mark (\u200E)
    self.email = email.to_s.gsub(/[\u200B-\u200F]/, '').strip
  end

  def contact
    @contact ||= person.try(:contacts).try(:first)
  end
end
