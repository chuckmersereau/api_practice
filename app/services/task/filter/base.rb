class Task::Filter::Base < ApplicationFilter
  private

  def clean_contact_filter(filters)
    (filters.keys.map { |k| k.to_s.sub(/contact_/i, '').to_sym }.zip filters.values).to_h
  end

  def contact_scope(tasks)
    Contact.joins(:activity_contacts).where(activity_contacts: { activity: tasks })
  end
end
