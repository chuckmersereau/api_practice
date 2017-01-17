class Contact::Duplicate
  attr_reader :id, :contacts
  alias read_attribute_for_serialization send

  def self.find(id)
    contacts = id.split('~').map do |contact_id|
      Contact.find(contact_id)
    end
    new(*contacts)
  end

  def all_for_account_list(account_list)
    Contact::DuplicatesFinder.new(account_list).find
  end

  def initialize(contact_1, contact_2)
    @contacts = [contact_1, contact_2].sort_by(&:id).freeze
    @id = @contacts.map(&:id).join('~').freeze
  end

  def invalidate!
    contact_1, contact_2 = contacts
    Contact.transaction do
      contact_1.confirm_not_duplicate_of!(contact_2)
      contact_2.confirm_not_duplicate_of!(contact_1)
    end
  end
end
