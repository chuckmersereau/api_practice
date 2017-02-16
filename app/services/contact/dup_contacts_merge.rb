class Contact::DupContactsMerge
  def initialize(contacts)
    @contacts = contacts
  end

  def merge_duplicates
    merged_contacts = []

    ordered_contacts = contacts.includes(:addresses, :donor_accounts).order('contacts.created_at')
    ordered_contacts.each do |contact|
      next if merged_contacts.include?(contact)

      other_contacts = ordered_contacts.select do |c|
        c.name == contact.name &&
          c.id != contact.id &&
          (c.donor_accounts.first == contact.donor_accounts.first ||
           c.addresses.find { |a| contact.addresses.find { |ca| ca.equal_to? a } })
      end
      next unless other_contacts.present?
      other_contacts.each do |other_contact|
        contact.merge(other_contact)
        merged_contacts << other_contact
      end
    end

    contacts.reload
    contacts.each(&:merge_people)
    contacts.each(&:merge_addresses)
  end

  private

  attr_reader :contacts
end
