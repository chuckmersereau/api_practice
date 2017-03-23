class ConstantList < ActiveModelSerializers::Model
  include DisplayCase::ExhibitsHelper

  delegate :alert_frequencies, to: :Task
  delegate :assignable_locations, to: :address
  delegate :assignable_statuses, to: :contact

  def activities
    @activities ||= ::Task::TASK_ACTIVITIES
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

  def next_actions
    @next_actions ||= dup_hash_of_arrays(Task.all_next_action_options.dup)
  end

  def results
    @results ||= dup_hash_of_arrays(Task.all_result_options.dup)
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
    NotificationType.all.inject({}) do |hash, nt|
      hash.merge!(nt.uuid => nt.description)
    end
  end

  def organizations_hash
    Organization.active.all.inject({}) do |hash, org|
      hash.merge!(org.uuid => org.name)
    end
  end

  # For some reason, ActiveModelSerializer tries to somehow modify the elements
  # that it serializes. If an array being serialized has been frozen, a "can't
  # modify frozen Array" error will be raised.
  def dup_hash_of_arrays(hash)
    Hash[hash.map { |k, v| [k, v.dup] }]
  end
end
