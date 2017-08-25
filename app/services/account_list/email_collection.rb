class AccountList::EmailCollection
  attr_reader :account_list

  def initialize(account_list)
    @account_list = account_list
  end

  def grouped_by_email
    @grouped_by_email ||= group_collection_by_email
  end

  private

  def fetch_email_collection_for_account_list
    account_list
      .contacts
      .active
      .joins(people: [:email_addresses])
      .where(email_addresses: { deleted: false })
      .pluck(:contact_id, 'people.id', 'email_addresses.email')
  end

  def group_collection_by_email
    fetch_email_collection_for_account_list.each_with_object({}) do |record_data_array, hash|
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
