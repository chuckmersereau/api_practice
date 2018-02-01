# https://github.com/CruGlobal/mpdx_api/pull/936

class RunOnce::EmailAddressUniqueAndCaseSensitiveWorker
  include Sidekiq::Worker

  sidekiq_options queue: :run_once, unique: :until_executed

  def perform
    duplicates =
      EmailAddress.group(:person_id, :source, 'lower(email)')
                  .having('count(*) > 1')
                  .pluck('array_agg(id) as ids', :person_id, :source, 'lower(email) as email')

    duplicates.each do |duplicate|
      email_addresses = EmailAddress.where(id: duplicate[0]).all
      email_addresses = sort_email_addresses(email_addresses)
      email_addresses.pop
      email_addresses.each(&:destroy)
    end
  end

  protected

  def sort_email_addresses(email_addresses)
    email_addresses.sort_by do |email_address|
      bool_to_int(email_address.primary) +
        bool_to_int(email_address.deleted) +
        bool_to_int(email_address.historic) +
        bool_to_int(!email_address.valid_values) +
        bool_to_int(!email_address.remote_id.present?)
    end
  end

  def bool_to_int(bool)
    bool ? 0 : 1
  end
end
