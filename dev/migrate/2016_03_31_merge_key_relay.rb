class KeyRelayMerge
  def merge
    lookup_existing_relay_guids
    move_key_accounts
  end

  def lookup_existing_relay_guids
    total_count = Person::RelayAccount.where(key_remote_id: nil).count
    diff_count = 0

    Person::RelayAccount.where(key_remote_id: nil).find_each do |relay_account|
      key_guid = find_key_guid(relay_account)
      diff_count += 1 unless key_guid.casecmp(relay_account.remote_id.upcase).zero?
      relay_account.update(key_remote_id: key_guid)
    end

    p "updated #{total_count} RelayAccounts, #{diff_count} of those were different"
  end

  def move_key_accounts
    total_count = OldKeyAccount.count
    count = 0

    OldKeyAccount.find_each do |key_account|
      OldKeyAccount.transaction do
        relay_guid = find_relay_guid(key_account)
        relay_account = Person::RelayAccount.find_by('upper(remote_id) = ?', relay_guid.upcase)
        relay_account ||= Person::RelayAccount.new
        if relay_account.id.blank? || relay_account.updated_at < key_account.updated_at
          attributes = key_account.attributes.with_indifferent_access
                                  .slice(:person_id, :first_name, :last_name, :authenticated, :created_at, :updated_at)
          attributes[:username] = key_account.email
          relay_account.attributes = attributes
        end
        count += 1 if relay_account.id.blank?
        relay_account.remote_id ||= relay_guid
        relay_account.key_remote_id = key_account.remote_id
        relay_account.save!

        # Don't delete the Key Accounts until we test it, plus it's faster this way
        # key_account.destroy!
      end
    end

    p "updated #{total_count} KeyAccounts, #{count} of those didn't exist already"
  end

  private

  def find_relay_guid(key_account)
    key_guid = key_account.key_remote_id.upcase
    relay_guid = csv_rows.find { |row| row[:thekeyguid]&.upcase == key_guid }.try(:[], :relayguid)
    relay_guid || key_guid
  end

  def find_key_guid(relay_account)
    relay_guid = relay_account.remote_id.upcase
    key_guid = csv_rows.find { |row| row[:relayguid]&.upcase == relay_guid }.try(:[], :thekeyguid)
    key_guid || relay_guid
  end

  def csv_rows
    return @csv_rows if @csv_rows
    csv_text = fog.get_object(ENV.fetch('AWS_BUCKET'), 'mismatched guids.csv').body
    @csv_rows = CSV.parse(csv_text, headers: true, header_converters: :symbol)
  end

  def fog
    @fog ||=
      Fog::Storage.new(
        provider: 'AWS',
        aws_access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
        aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'))
  end
end

class OldKeyAccount < ActiveRecord::Base
  self.table_name = 'person_key_accounts'
end
