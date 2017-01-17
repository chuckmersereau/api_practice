class AccountList::DuplicatesFinder
  def initialize(account_list)
    @account_list = account_list
  end

  protected

  def exec_query(sql)
    # Scope to the account list
    sql = sql.gsub(':account_list_id', @account_list.id.to_s)
    AccountList.connection.exec_query(sql)
  end

  def create_temp_tables
    drop_temp_tables
    CREATE_TEMP_TABLES_SQL_QUERIES.each(&method(:exec_query))
  end

  def drop_temp_tables
    [
      'DROP TABLE IF EXISTS tmp_account_ppl',
      'DROP TABLE IF EXISTS tmp_unsplit_names',
      'DROP TABLE IF EXISTS tmp_names',
      'DROP TABLE IF EXISTS tmp_dups_by_name',
      'DROP TABLE IF EXISTS tmp_dups_by_contact_info',
      'DROP TABLE IF EXISTS tmp_name_male_ratios',
      'DROP TABLE IF EXISTS tmp_dups'
    ].each(&method(:exec_query))
  end

  # To help prevent merging a male person with a female person (and because the
  # gender field can be unreliable), we use the name_male_ratios table which has
  # data on male ratios of people. To avoid false positives with duplicate
  # matching, require a certain threshold of the name ratio to confidently
  # assume the person is male/female for the sake of suggesting duplicates.

  # Assume male if more than this ratio with name are male
  MALE_NAME_CONFIDENCE_LVL = 0.9
  # Assume female if fewer than this ratio with name are male
  FEMALE_NAME_CONFIDENCE_LVL = 0.1

  # The reason these are large queries with temp tables and not Ruby code with
  # loops is that as I introduced more duplicate search options, that code got
  # painfully slow and so I re-wrote the logic as self-join queries for
  # performance. # Temporary tables are unique per database connection and the
  # Rails connection pool gives each thread a unique connection, so it's OK for
  # this model to create temporary tables even if another instance somewhere
  # else is doing the same action and creating its own temp tables with the same
  # names. See:
  # http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/ConnectionPool.html
  # http://www.postgresql.org/docs/9.4/static/sql-createtable.html  under
  # "Compatibility", "Temporary Tables"
  CREATE_TEMP_TABLES_SQL_QUERIES = [
    # First just scope people to the account list and filter out anonymous
    # contacts or people with name "Unknown".
    <<~SQL,
      SELECT people.id, first_name, legal_first_name, middle_name, last_name
      INTO TEMP tmp_account_ppl
      FROM people
        INNER JOIN contact_people ON people.id = contact_people.person_id
        INNER JOIN contacts ON contacts.id = contact_people.contact_id
      WHERE contacts.account_list_id = :account_list_id
        AND contacts.name NOT ilike '%nonymous%'
        AND first_name NOT ilike '%nknow%'
    SQL

    'CREATE INDEX ON tmp_account_ppl (id)',

    # Next combine in the three name fields: first_name, legal_first_name,
    # middle_name and track first/middle distinction.
    <<~SQL,
    SELECT *
    INTO TEMP tmp_unsplit_names
    FROM (
      SELECT first_name AS name, 'first' AS name_field, id, first_name,
             last_name
      FROM tmp_account_ppl

      UNION

      SELECT legal_first_name, 'legal_first' AS name_field, id, first_name,
             last_name
      FROM tmp_account_ppl
      WHERE legal_first_name IS NOT NULL AND legal_first_name <> ''

      UNION

      SELECT middle_name, 'middle' AS name_field, id, first_name, last_name
      FROM tmp_account_ppl
      WHERE middle_name IS NOT NULL AND middle_name <> ''
    ) AS people_unsplit_names_query
    SQL

    # Break apart various parts of names (initials, capitals, spaces, etc.) into
    # a single table, and make names lowercase. Also filter out people with
    # names like "Friend of the ministry"
    <<~SQL,
    SELECT lower(name) AS name, name_field, id, first_name,
           lower(last_name) AS last_name
    INTO TEMP tmp_names
    FROM (
        /* Try replacing the space to match e.g. 'Marybeth' and 'Mary Beth'.
         * This also brings in all names that don't match patterns below. */
        SELECT replace(name, ' ', '') AS name, name_field, id, first_name,
               last_name
        FROM tmp_unsplit_names
      UNION
        /* Split the name by '-', ' ', and '.' to capture initials and multiple
         * names like 'J.W.' or 'John Wilson' * The regexp_replace is to get rid
         * of any separator characters at the end to reduce blank rows. */
        SELECT regexp_split_to_table(
                 regexp_replace(name, '[\\.-]+$', ''),
                 '([\\. -]+|$)+'
               ), name_field, id, first_name, last_name
        FROM tmp_unsplit_names WHERE name ~ '[\\. -]'
      UNION
        /* Split the name by  two capitals in a row like 'JW' or a capital
         * within a name like 'MaryBeth', but don't split * three letter
         * capitals which are common in organization acrynomys like 'CCC NEHQ'
         * or 'City UMC'  */
        SELECT regexp_split_to_table(
                 regexp_replace(name, '(^[A-Z]|[a-z])([A-Z])', '\\1 \\2'),
                 ' '
               ), name_field, id, first_name, last_name
        FROM tmp_unsplit_names
        WHERE name ~ '(^[A-Z]|[a-z])([A-Z])' AND name !~ '[A-Z]{3}'
    ) AS people_names_query
    WHERE first_name || last_name NOT ilike 'friend%of%the%ministry'
    SQL
    'CREATE INDEX ON tmp_names (id)',
    'CREATE INDEX ON tmp_names (name)',
    'CREATE INDEX ON tmp_names (last_name)',

    # Join the names table to itself to find duplicate names. Require a match on
    # last name, and then a match either by matching name, a (name, nickname)
    # pair or a matching initial. Don't allow matches just by middle names.
    # Order the person_id, dup_person_id so that the person_id (the default
    # winner in the merge) will have reasonable defaults for which of the two
    # names is picked. Those defaults are reflected in the priority field.
    <<~SQL,
    SELECT ppl.id AS person_id, dups.id AS dup_person_id,
      nicknames.id AS nickname_id,
      CASE
        /* Nickname over the long name (Dave over David) */
        WHEN ppl.name = nicknames.nickname THEN 800

        /* Prefer first name over middle when first name is well-formed
           (David over John David) */
        WHEN dups.name_field = 'middle' AND
          ppl.first_name ~ '^[A-Z].*[a-z]' THEN 700

        /* Prefer names with inside capitals (MaryBeth over Marybeth) */
        WHEN ppl.first_name ~ '^[A-Z][a-z]+[A-Z][a-z]' THEN 600

        /* Prefer two letter initials (CS over Clive Staples) */
        WHEN ppl.first_name ~ '^[A-Z][A-Z]$|^[A-Z]\\.\s?[A-Z]\\.$' THEN 500

        /* Prefer multi-word names (Mary Beth over Mary) */
        WHEN ppl.first_name ~ '^[A-Z][A-Za-z]+ [A-Z][a-z]' THEN 400

        /* Prefer names that start with upper case, end with a lower case,
           and don't start with an initial. (John over D John, john, J. or J) */
        WHEN ppl.first_name ~ '^[A-Z]([^\s\\.].*)?[a-z]$' THEN 300

        /* More arbitrary preference by id.  */
        WHEN dups.id > ppl.id THEN 100 ELSE 50
      END AS priority,

      /* Verify genders if the match used a middle (or legal first) name/initial
         as those are more often wrong in the data. */
      (
        char_length(ppl.name) = 1 OR char_length(dups.name) = 1
          OR dups.name_field <> 'first' OR ppl.name_field <> 'first'
      ) AS check_genders,

      ppl.name_field, dups.name_field AS dup_name_field
    INTO TEMP tmp_dups_by_name
    FROM tmp_names AS ppl
      INNER JOIN tmp_names AS dups ON ppl.id <> dups.id
      LEFT JOIN nicknames ON nicknames.suggest_duplicates = 't'
        AND ((ppl.name = nicknames.nickname AND dups.name = nicknames.name)
          OR (ppl.name = nicknames.name AND dups.name = nicknames.nickname))
    WHERE ppl.last_name = dups.last_name
      AND (ppl.name_field = 'first' OR dups.name_field = 'first')
      AND (
        nicknames.id IS NOT NULL
        OR (dups.name = ppl.name AND char_length(ppl.name) > 1)
        OR ((char_length(dups.name) = 1 OR char_length(ppl.name) = 1)
          AND (
            dups.name = substring(ppl.name from 1 for 1)
            OR ppl.name = substring(dups.name from 1 for 1)
          )
        )
      )
    SQL
    'CREATE INDEX ON tmp_dups_by_name (person_id)',
    'CREATE INDEX ON tmp_dups_by_name (dup_person_id)',

    # Join the emails and phone number tables together to find duplicate people
    # by contact info. Always check gender for these matches as husband and wife
    # often have common contact info. Strip out non-numeric characters from the
    # phone numbers as we match them
    <<~SQL,
    SELECT *, true AS check_genders
    INTO TEMP tmp_dups_by_contact_info
    FROM (
      SELECT ppl.id AS person_id, dups.id AS dup_person_id
      FROM tmp_account_ppl AS ppl
      INNER JOIN tmp_account_ppl AS dups ON ppl.id <> dups.id
      INNER JOIN email_addresses ON email_addresses.person_id = ppl.id
      INNER JOIN email_addresses AS dup_email_addresses ON
        dup_email_addresses.person_id = dups.id
      WHERE lower(email_addresses.email) = lower(dup_email_addresses.email)

      UNION

      SELECT ppl.id AS person_id, dups.id AS dup_person_id
      FROM tmp_account_ppl AS ppl
      INNER JOIN tmp_account_ppl AS dups ON ppl.id <> dups.id
      INNER JOIN phone_numbers ON phone_numbers.person_id = ppl.id
      INNER JOIN phone_numbers AS dup_phone_numbers ON
        dup_phone_numbers.person_id = dups.id
      WHERE regexp_replace(phone_numbers.number, \ '[^0-9]\', \ '\', \ 'g\') =
        regexp_replace(dup_phone_numbers.number, \ '[^0-9]\', \ '\', \ 'g\')
    ) tmp_dups_by_contact_info_query
    SQL
    'CREATE INDEX ON tmp_dups_by_contact_info (person_id)',
    'CREATE INDEX ON tmp_dups_by_contact_info (dup_person_id)',

    # Join to the name_male_ratios table and get an average name male ratio for
    # the various name parts of a person.
    <<~SQL,
    SELECT tmp_names.id, AVG(name_male_ratios.male_ratio) AS male_ratio
    INTO TEMP tmp_name_male_ratios
    FROM tmp_names
    LEFT JOIN name_male_ratios ON tmp_names.name = name_male_ratios.name
    GROUP BY tmp_names.id
    SQL
    'CREATE INDEX ON tmp_name_male_ratios (id)',

    # Combine the duplicate people by name and contact info and join it to the
    # name male ratios table. Only select as duplicates pairs whose name male
    # ratios strongly agree, or pairs without that info and which match on the
    # gender field (or don't have gender info). The gender field by itself isn't
    # a strong enough indicator because it can often be wrong. (E.g. if in Tnt
    # someone puts the husband and wife in opposite fields then imports.)
    <<~SQL,
    SELECT dups.*
    INTO TEMP tmp_dups
    FROM (
      SELECT person_id, dup_person_id, nickname_id, priority, check_genders,
             name_field,dup_name_field
      FROM tmp_dups_by_name

      UNION

      SELECT person_id, dup_person_id, NULL, NULL, check_genders, NULL, NULL
      FROM tmp_dups_by_contact_info
    ) dups
    INNER JOIN people ON dups.person_id = people.id
    INNER JOIN people AS dup_people ON dups.dup_person_id = dup_people.id
    LEFT JOIN tmp_name_male_ratios name_male_ratios ON
      name_male_ratios.id = people.id
    LEFT JOIN tmp_name_male_ratios dup_name_male_ratios ON
      dup_name_male_ratios.id = dup_people.id
    WHERE check_genders = 'f'
      OR (
        (
          name_male_ratios.male_ratio IS NULL
          OR dup_name_male_ratios.male_ratio IS NULL
        )
        AND (
          people.gender = dup_people.gender
          OR people.gender IS NULL
          OR dup_people.gender IS NULL
        )
        OR (
          name_male_ratios.male_ratio < #{FEMALE_NAME_CONFIDENCE_LVL}
          AND dup_name_male_ratios.male_ratio < #{FEMALE_NAME_CONFIDENCE_LVL}
        )
        OR (
          name_male_ratios.male_ratio > #{MALE_NAME_CONFIDENCE_LVL}
          AND dup_name_male_ratios.male_ratio > #{MALE_NAME_CONFIDENCE_LVL}
        )
      )
    SQL
    'CREATE INDEX ON tmp_dups (person_id)',
    'CREATE INDEX ON tmp_dups (dup_person_id)'
  ].freeze
end
