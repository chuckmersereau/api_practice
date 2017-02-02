class ConstantList < ActiveModelSerializers::Model
  include DisplayCase::ExhibitsHelper

  delegate :assignable_locations, to: :address
  delegate :assignable_statuses, to: :contact

  def activities
    @activities ||= ::Task::TASK_ACTIVITIES.dup
  end

  def assignable_likely_to_give
    contact.assignable_likely_to_gives
  end

  def assignable_send_newsletter
    contact.assignable_send_newsletters
  end

  def pledge_frequencies
    Contact.pledge_frequencies
  end

  def statuses
    contact.assignable_statuses
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

  def bulk_update_options
    Contact.bulk_update_options(current_account_list)
  end

  def next_actions
    Task.all_next_action_options
  end

  def results
    Task.all_result_options
  end

  private

  def address
    @address ||= Address.new
  end

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
      NotificationType.all.map { |nt| [nt.id, nt.description] }
    ]
  end

  def organizations_hash
    Hash[
      Organization.active.all.map { |org| [org.id, org.name] }
    ]
  end
end
