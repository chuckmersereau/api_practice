class Contact::SuggestedChangesUpdater
  attr_reader :contact

  def initialize(contact:)
    @contact = contact
  end

  def update_status_suggestions
    return if status_confirmed_recently?
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
      suggested_changes: suggested_changes,
      status_valid: suggested_changes.blank?
    }
  end

  def status_confirmed_recently?
    contact.status_confirmed_at && contact.status_confirmed_at > 1.year.ago
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

    # Don't suggest nil for certain attributes.
    [:status, :pledge_currency].each do |attribute|
      suggested_changes.delete(attribute) if suggested_changes[attribute].blank?
    end

    # nil and 0 are equivalent for certain attributes.
    [:pledge_frequency, :pledge_amount].each do |attribute|
      suggested_changes.delete(attribute) if [0, nil].include?(suggested_changes[attribute]) && [0, nil].include?(@contact.send(attribute))
    end
  end

  def load_suggested_attribute(suggested_change_attribute, suggested_change_value)
    if contact.send(suggested_change_attribute) != suggested_change_value
      suggested_changes[suggested_change_attribute] = suggested_change_value
    else
      suggested_changes.delete(suggested_change_attribute)
    end
  end
end
