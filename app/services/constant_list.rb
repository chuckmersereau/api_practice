class ConstantList < ActiveModelSerializers::Model
  include DisplayCase::ExhibitsHelper

  def activities
    @activities ||= ::Task::TASK_ACTIVITIES.dup
  end

  def assignable_likely_to_give
    contact.assignable_likely_to_gives.map { |s| [s, s] }
  end

  def assignable_send_newsletter
    contact.assignable_send_newsletters.map { |s| [s, s] }
  end

  def pledge_frequencies
    Contact.pledge_frequencies.invert.to_a
  end

  def statuses
    contact.assignable_statuses.map { |s| [s, s] }
  end

  def codes
    @codes ||= TwitterCldr::Shared::Currencies.currency_codes
  end

  def locales
    @locales ||= locales_hash.invert.sort_by(&:first)
  end

  def notifications
    @notifications ||= notifications_hash
  end

  def organizations
    @organizations ||= organizations_hash
  end

  private

  def contact
    @contact ||= Contact.new
  end

  def locales_hash
    TwitterCldr::Shared::Languages
      .all
      .select { |k, _| TwitterCldr.supported_locales.include?(k) }
  end

  def notifications_hash
    Hash[
      NotificationType.all.map { |nt| [nt.id, nt] }
    ]
  end

  def organizations_hash
    Hash[
      Organization.active.all.map { |org| [org.id, org] }
    ]
  end
end
