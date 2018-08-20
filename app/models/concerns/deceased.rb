# frozen_string_literal: true

module Deceased
  extend ActiveSupport::Concern

  included do
    scope :non_deceased, -> { where(deceased: false) }
    scope :deceased, -> { where(deceased: true) }
    before_save :deceased_check
  end

  class_methods do
    def are_all_deceased?
      deceased.count == count
    end

    def not_all_deceased?(id)
      non_deceased.where.not(id: id).exists?
    end
  end

  def deceased_check
    return unless deceased_changed? && deceased?

    self.optout_enewsletter = true

    contacts.each do |contact|
      if contact.people.not_all_deceased?(id)
        contact_updates = strip_name_from_greetings(contact)
        clear_primary_person(contact)
      else
        contact_updates = update_contact_when_all_people_are_deceased
      end

      next if contact_updates.blank?

      contact_updates[:updated_at] = Time.current
      # Call update_columns instead of save because a save of a contact can trigger saving its people which
      # could eventually call this very deceased_check method and cause an infinite recursion.
      contact.update_columns(contact_updates)
    end
  end

  private

  def update_contact_when_all_people_are_deceased
    contact_updates = {}

    # we should update their Newsletter Status to None
    reset_newsletter_status(contact_updates)

    # their Send Appeals to no
    reset_appeals(contact_updates)

    # and their Partner Status to Never Ask
    reset_partner_status(contact_updates)

    contact_updates
  end

  def reset_partner_status(contact_updates)
    contact_updates.merge!(status: 'Never Ask')
  end

  def reset_appeals(contact_updates)
    contact_updates.merge!(no_appeals: true)
  end

  def reset_newsletter_status(contact_updates)
    contact_updates.merge!(send_newsletter: 'None')
  end

  # We need to access the field value directly via c[:greeting] because c.greeting defaults to the first name
  # even if the field is nil. That causes an infinite loop here where it keeps trying to remove the first name
  # from the greeting but it keeps getting defaulted back to having it.
  def strip_name_from_greetings(contact, contact_updates = {})
    if contact[:greeting].present? && contact[:greeting].include?(first_name)
      contact_updates[:greeting] = contact.greeting.sub(first_name, '').sub(/ #{_('and')} /, ' ').strip
    end
    contact_updates[:envelope_greeting] = '' if contact[:envelope_greeting].present?
    contact_updates = strip_first_name(contact, contact_updates)
    contact_updates
  end

  def strip_first_name(contact, contact_updates = {})
    if contact.name.include?(first_name)
      # remove the name
      contact_updates[:name] = contact.name.sub(first_name, '').sub(/ & | #{_('and')} /, '').strip
    end
    contact_updates
  end

  def clear_primary_person(contact)
    if contact.primary_person_id == id && contact.people.count > 1
      # This only modifies associated people via update_column, so we can call it directly
      contact.clear_primary_person
    end
  end
end
