class TntImport::DonorAccountsImport
  # Donation Services seems to pad donor accounts with zeros up to length 9. TntMPD does not though.
  DONOR_NUMBER_NORMAL_LEN = 9

  def initialize(xml, orgs_by_tnt_id)
    @xml = xml
    @orgs_by_tnt_id = orgs_by_tnt_id || {}
  end

  def import
    return {} unless @xml['Donor'].present?

    donors_by_tnt_contact_id = {}

    Array.wrap(@xml['Donor']['row']).each do |row|
      contact_tnt_id = row['ContactID']
      donors_by_tnt_contact_id[contact_tnt_id] ||= []
      donor = add_or_update_donor(row)
      donors_by_tnt_contact_id[contact_tnt_id] << donor if donor.present?
    end

    donors_by_tnt_contact_id
  end

  def add_or_update_donor(row)
    org = @orgs_by_tnt_id[row['OrganizationID']]
    return unless org.present?

    account_number = row['OrgDonorCode']
    da = find_donor_account(org, account_number)
    if da
      da.update(name: row['OrgDonorName']) if da.name.blank?
      da
    else
      create_donor_account(org, account_number, row)
    end
  end

  def find_donor_account(org, account_number)
    padded_account_number = account_number.rjust(DONOR_NUMBER_NORMAL_LEN, '0')
    org.donor_accounts.find_by(account_number: [account_number, padded_account_number])
  end

  def create_donor_account(org, account_number, row)
    da = org.donor_accounts.new(account_number: account_number,
                                name: row['OrgDonorName'])
    add_address(da, row)
    da.save!
    da
  end

  def add_address(donor_account, row)
    donor_account.addresses_attributes = [
      {
        street: row['StreetAddress'],
        city:  row['City'],
        state: row['State'],
        postal_code: row['PostalCode'],
        country: tnt_country(row['CountryID']),
        primary_mailing_address: true,
        source: 'TntImport',
        start_date: Date.current
      }
    ]
  end

  def tnt_country(tnt_id)
    country = tnt_countries[tnt_id]
    country == 'United States of America' ? 'United States' : country
  end

  def tnt_countries
    @tnt_countries ||= TntImport::CountriesParser.countries_by_tnt_id(@xml)
  end
end
