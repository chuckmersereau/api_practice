class Contact::DuplicatesFinder < AccountList::DuplicatesFinder
  def find
    create_temp_tables
    find_duplicates
  ensure
    drop_temp_tables
  end

  private

  def find_duplicates
    # Grab an array of two-element arrays of IDs representing duplicate contacts
    duplicate_id_pairs = query_duplicate_id_pairs

    # Load all the referenced Contacts by ID
    contacts = Contact.find(duplicate_id_pairs.to_a.flatten.uniq)

    # Store the contacts in a hash so that we don't need to query the DB for
    # each ID, should one ID happen to be referenced in two pairs
    contacts_by_id = contacts.each_with_object({}) do |contact, cache|
      cache[contact.id] = contact
    end

    # Transform the array of ID pairs into an array of Contact pairs
    contact_sets = duplicate_id_pairs.map do |pair|
      first_contact = contacts_by_id[pair.first.to_i]
      second_contact = contacts_by_id[pair.second.to_i]

      [first_contact, second_contact]
    end

    # Prune Contact pairs that are already known to not be duplicates
    # Sort the array of pairs by the name of the first Contact in the pair
    # AND finally return a List of Contact::Duplicate objects
    contact_sets
      .reject { |(first, second)| first.confirmed_non_duplicate_of?(second) }
      .sort_by { |(first, _second)| first.name }
      .map { |(first, second)| Contact::Duplicate.new(first, second) }
  end

  def query_duplicate_id_pairs
    duplicate_id_pairs = Set.new
    dup_contacts_query.each do |row|
      duplicate_id_pairs << row.sort
    end
    duplicate_id_pairs.to_a
  end

  def dup_contacts_query
    exec_query(DUP_CONTACTS_SQL).rows
  end

  # Join the duplicate people table to the contacts to find duplicate people in
  # different contacts, but don't allow a match based on middle name as that
  # seemed too agressive for contact to contact matching. Also try to match
  # based on the master_address_id of the primary mailing address.
  DUP_CONTACTS_SQL = <<~SQL.freeze
    SELECT contact_people.contact_id,
      dup_contact_people.contact_id AS dup_contact_id
    FROM tmp_dups
    INNER JOIN contact_people ON contact_people.person_id = tmp_dups.person_id
    INNER JOIN contact_people dup_contact_people
      ON dup_contact_people.person_id = tmp_dups.dup_person_id
    INNER JOIN people ON tmp_dups.person_id = people.id
    INNER JOIN people AS dup_people ON tmp_dups.dup_person_id = dup_people.id
    WHERE contact_people.contact_id <> dup_contact_people.contact_id
      AND coalesce(tmp_dups.name_field, '') <> 'middle'
      AND coalesce(tmp_dups.dup_name_field, '') <> 'middle'
      AND dup_people.first_name || dup_people.last_name
        NOT ilike 'friend%of%the%ministry'
      AND people.first_name || people.last_name
        NOT ilike 'friend%of%the%ministry'
    UNION
    SELECT contacts.id, dup_contacts.id
    FROM contacts
      INNER JOIN contacts AS dup_contacts ON contacts.id < dup_contacts.id
      INNER JOIN addresses
        ON addresses.addressable_type = 'Contact'
          AND addresses.addressable_id = contacts.id
      INNER JOIN addresses AS dup_addresses
        ON dup_addresses.addressable_type = 'Contact'
          AND dup_addresses.addressable_id = dup_contacts.id
    WHERE
      contacts.account_list_id = :account_list_id
      AND dup_contacts.account_list_id = :account_list_id
      AND contacts.name NOT ilike '%nonymous%'
      AND dup_contacts.name NOT ilike '%nonymous%'
      AND addresses.primary_mailing_address = 't'
      AND dup_addresses.primary_mailing_address = 't'
      AND addresses.street NOT ilike '%insufficient%'
      AND dup_addresses.street NOT ilike '%insufficient%'
      AND addresses.street IS NOT NULL
      AND dup_addresses.street IS NOT NULL
      AND addresses.street <> ''
      AND dup_addresses.street <> ''
      AND addresses.deleted <> 't'
      AND dup_addresses.deleted <> 't'
      AND addresses.master_address_id = dup_addresses.master_address_id
  SQL
end
