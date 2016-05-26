def default_contact_locales_from_orgs
  sql = '
    WITH contact_locales AS (
      SELECT contacts.id as contact_row_id, organizations.locale as org_locale
      FROM contacts
      INNER JOIN contact_donor_accounts cda on cda.contact_id = contacts.id
      INNER JOIN donor_accounts on cda.donor_account_id = donor_accounts.id
      INNER JOIN organizations on organizations.id = donor_accounts.organization_id
    )
    UPDATE contacts
    SET locale = contact_locales.org_locale
    FROM contact_locales
    WHERE contacts.id = contact_locales.contact_row_id
    AND contacts.locale is null'

  Contact.connection.execute(sql)
end
