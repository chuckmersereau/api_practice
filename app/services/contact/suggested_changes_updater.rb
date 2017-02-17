class Contact::SuggestedChangesUpdater
  attr_reader :contact

  def initialize(contact:)
    @contact = contact
  end

  def update_status_suggestions
    build_suggested_changes
    contact.update_columns(updates)
  end

  private

  attr_accessor :suggested_changes

  private(*delegate(:suggested_pledge_frequency,
                    :suggested_pledge_amount,
                    :suggested_pledge_currency,
                    :suggested_status,
                    :contact_has_stopped_giving?,
                    to: :status_suggester))

  def status_suggester
    @status_suggester ||= Contact::StatusSuggester.new(contact: contact)
  end

  def updates
    {
      status_validated_at: Time.current,
      suggested_changes: suggested_changes,
      status_valid: suggested_changes.blank?
    }
  end

  def build_suggested_changes
    self.suggested_changes = contact.suggested_changes || {}

    if contact_has_stopped_giving?
      load_suggested_attribute(:pledge_frequency, nil)
      load_suggested_attribute(:pledge_amount,    nil)
      load_suggested_attribute(:pledge_currency,  nil)
    else
      load_suggested_attribute(:pledge_frequency, suggested_pledge_frequency)
      load_suggested_attribute(:pledge_amount,    suggested_pledge_amount)
      load_suggested_attribute(:pledge_currency,  suggested_pledge_currency)
    end

    load_suggested_attribute(:status, suggested_status)
  end

  def load_suggested_attribute(suggested_change_attribute, suggested_change_value)
    if contact.send(suggested_change_attribute) != suggested_change_value
      suggested_changes[suggested_change_attribute] = suggested_change_value
    end
  end
end
