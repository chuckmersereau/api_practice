class AccountListEmailCollection
  attr_reader :account_list

  def initialize(account_list)
    @account_list = account_list
  end

  def data
    @data ||= fetch_email_data_for_account_list
  end

  def emails
    @emails ||= indexed_data.keys.sort
  end

  def indexed_data
    @indexed_data ||= index_data
  end

  private

  def fetch_email_data_for_account_list
    account_list
      .contacts
      .active
      .joins(people: [:email_addresses])
      .pluck(:contact_id, 'people.id', 'email_addresses.email')
  end

  def index_data
    data.each_with_object({}) do |record_data_array, hash|
      contact_id, person_id, email = record_data_array

      normalized_email = email.downcase.strip
      record_data_hash = {
        contact_id: contact_id,
        person_id: person_id,
        email: email
      }

      hash[normalized_email] ||= []
      hash[normalized_email] << record_data_hash
    end
  end
end
