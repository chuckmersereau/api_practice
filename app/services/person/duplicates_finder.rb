class Person::DuplicatesFinder < AccountList::DuplicatesFinder
  def find
    create_temp_tables
    find_duplicates
  ensure
    drop_temp_tables
  end

  private

  def find_duplicates
    dup_rows = unique_duplicate_people_rows

    # Update the nickname times offered counter to track which nicknames end up
    # being useful
    Nickname.update_counters(
      dup_rows.map { |r| r[:nickname_id] }.compact,
      num_times_offered: 1
    )

    # Load all the referenced Contacts by ID and store them in a hash so that we
    # don't need to query the DB for each ID, should one ID happen to be
    # referenced in two pairs
    contacts_by_id = Contact.find(extract_contact_ids_from_rows(dup_rows))
                            .each_with_object({}) do |contact, cache|
                              cache[contact.id] = contact
                            end

    # Load all the referenced People by ID and store them in a hash so that we
    # don't need to query the DB for each ID, should one ID happen to be
    # referenced in two pairs
    people_by_id = Person.find(extract_person_ids_from_rows(dup_rows))
                         .each_with_object({}) do |person, cache|
                           cache[person.id] = person
                         end

    people_sets = dup_rows.map do |row|
      Person::Duplicate.new(
        person: people_by_id[row[:person_id].to_i],
        dup_person: people_by_id[row[:dup_person_id].to_i],
        shared_contact: contacts_by_id[row[:contact_id].to_i]
      )
    end

    people_sets
      .reject { |dup| dup.person.confirmed_non_duplicate_of?(dup.dup_person) }
      .sort_by! { |dup| dup.shared_contact.name }
  end

  def extract_contact_ids_from_rows(rows)
    rows.map { |row| row[:contact_id] }.uniq
  end

  def extract_person_ids_from_rows(rows)
    rows.flat_map { |row| [row[:person_id], row[:dup_person_id]] }
        .uniq
  end

  def unique_duplicate_people_rows
    duplicate_id_pairs = Set.new
    dup_people_query.reject do |row|
      id_pair = [row[:person_id], row[:dup_person_id]].sort

      duplicate_id_pairs.include?(id_pair).tap { duplicate_id_pairs << id_pair }
    end
  end

  def dup_people_query
    exec_query(DUP_PEOPLE_SQL).to_hash.map(&:symbolize_keys)
  end

  # Join the duplicate people table to contact_people to find duplicate people
  # in the same contact. For duplicates by contact info, preference those whose
  # last name matches the "Last Name, .." pattern of the contact name. That
  # would correctly preference e.g. someone who joined the contact by maiden
  # name. Then preference a person with a last name at all. Check that the
  # people aren't both in the contact name, i.e. don't suggest Jane and John in
  # "Doe, John and Jane"
  DUP_PEOPLE_SQL = <<~SQL.freeze
    SELECT tmp_dups.person_id, dup_person_id, nickname_id,
      contact_people.contact_id,
      CASE
        when tmp_dups.priority IS NOT NULL THEN tmp_dups.priority
        WHEN contacts.name ilike ppl.last_name || ',%' THEN 10
        WHEN ppl.last_name IS NOT NULL AND ppl.last_name <> '' THEN 5
        WHEN ppl.id < dups.id THEN 3 ELSE 1
      END AS priority
    FROM tmp_dups
      INNER JOIN people ppl ON ppl.id = tmp_dups.person_id
      INNER JOIN people dups ON dups.id = tmp_dups.dup_person_id
      INNER JOIN contact_people ON contact_people.person_id = tmp_dups.person_id
      INNER JOIN contact_people AS dup_contact_people
        ON dup_contact_people.person_id = tmp_dups.dup_person_id
      INNER JOIN contacts ON contact_people.contact_id = contacts.id
    WHERE contact_people.contact_id = dup_contact_people.contact_id
      AND contacts.name NOT ilike (
        '%' || ppl.first_name || '% and %' || dups.first_name || '%'
      )
      and contacts.name NOT ilike (
        '%' || dups.first_name || '% and %' || ppl.first_name || '%'
      )
    ORDER BY priority DESC
  SQL
end
