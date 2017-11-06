class ConstantList < ActiveModelSerializers::Model
  include DisplayCase::ExhibitsHelper

  CURRENCY_CODES_NOT_NEEDED = %w(ADP AFA).freeze

  delegate :alert_frequencies, :mobile_alert_frequencies, to: :Task
  delegate :pledge_frequencies, to: :Contact
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

  def statuses
    contact.assignable_statuses
  end

  def codes
    @codes ||= TwitterCldr::Shared::Currencies.currency_codes - CURRENCY_CODES_NOT_NEEDED
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

  def organizations_attributes
    @organizations_attributes ||= organizations_attributes_hash
  end

  def next_actions
    @next_actions ||= dup_hash_of_arrays(Task.all_next_action_options.dup)
  end

  def results
    @results ||= dup_hash_of_arrays(Task.all_result_options.dup)
  end

  def csv_import
    @csv_import ||= {
      supported_headers: CsvImport.supported_headers,
      required_headers: CsvImport.required_headers,
      constants: CsvImport.constants,
      max_file_size_in_bytes: Import::MAX_FILE_SIZE_IN_BYTES,
      constants_from_top_level: {
        commitment_currency: :pledge_currencies,
        commitment_frequency: :pledge_frequency_hashes,
        likely_to_give: :assignable_likely_to_give_hashes,
        newsletter: :assignable_send_newsletter_hashes,
        send_appeals: :send_appeals_hashes,
        status: :status_hashes
      }
    }
  end

  def tnt_import
    {
      max_file_size_in_bytes: Import::MAX_FILE_SIZE_IN_BYTES
    }
  end

  def sources
    {
      addresses: %w(DataServer GoogleContactSync GoogleImport MPDX Siebel TntImport),
      email_addresses: ['MPDX'],
      phone_numbers: ['MPDX']
    }
  end

  def send_appeals
    {
      true => 'Yes',
      false => 'No'
    }
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
    Organization.active.order(name: :asc).inject({}) do |hash, org|
      hash.merge!(org.uuid => org.name)
    end
  end

  def organizations_attributes_hash
    Organization.active.order(name: :asc).inject({}) do |hash, org|
      hash.merge!(org.uuid => org_attributes_hash(org))
    end
  end

  def org_attributes_hash(org)
    {
      name: org.name,
      api_class: org.api_class.to_s,
      help_email: org.org_help_email,
      oauth: org.oauth?
    }
  end

  # For some reason, ActiveModelSerializer tries to somehow modify the elements
  # that it serializes. If an array being serialized has been frozen, a "can't
  # modify frozen Array" error will be raised.
  def dup_hash_of_arrays(hash)
    Hash[hash.map { |k, v| [k, v.dup] }]
  end
end
