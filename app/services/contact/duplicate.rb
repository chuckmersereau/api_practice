class Contact::Duplicate
  attr_reader :id, :contacts
  alias read_attribute_for_serialization send

  def self.find(id)
    contacts = id.split('~').map do |contact_uuid|
      Contact.find_by_uuid_or_raise!(contact_uuid)
    end
    new(*contacts)
  end

  def all_for_account_list(account_list)
    Contact::DuplicatesFinder.new(account_list).find
  end

  def initialize(contact_1, contact_2)
    @contacts = [contact_1, contact_2].sort_by(&:uuid).freeze
    @id = @contacts.map(&:uuid).join('~').freeze
  end

  def invalidate!
    contact_1, contact_2 = contacts
    Contact.transaction do
      contact_1.mark_not_duplicate_of!(contact_2)
      contact_2.mark_not_duplicate_of!(contact_1)
    end
  end

  def shares_an_id_with?(candidate_duplicate)
    id.include?(candidate_duplicate.contacts.first.uuid) || id.include?(candidate_duplicate.contacts.second.uuid)
  end
end
