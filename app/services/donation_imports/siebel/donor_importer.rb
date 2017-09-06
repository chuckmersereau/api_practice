class DonationImports::Siebel
  class DonorImporter
    attr_reader :siebel_import

    delegate :organization,
             :organization_account,
             :parse_date,
             to: :siebel_import

    delegate :designation_profiles, to: :organization_account

    def initialize(siebel_import)
      @siebel_import = siebel_import
    end

    def import_donors(date_from: nil)
      return unless designation_numbers.present?

      @date_from = date_from

      designation_profiles.each do |designation_profile|
        import_donors_by_designation_profile(designation_profile)
      end
    end

    private

    def import_donors_by_designation_profile(designation_profile)
      siebel_donors.each do |siebel_donor|
        donor_account = add_or_update_donor_account(designation_profile.account_list, siebel_donor)

        add_or_update_company(designation_profile.account_list, siebel_donor, donor_account) if siebel_donor.type == 'Business'
      end
    end

    def siebel_donors
      @siebel_donors ||= fetch_siebel_donors
    end

    def fetch_siebel_donors
      SiebelDonations::Donor.find(having_given_to_designations: designation_numbers.join(','),
                                  contact_filter: :all,
                                  account_address_filter: :primary,
                                  contact_email_filter: :all,
                                  contact_phone_filter: :all)
    end

    def designation_numbers
      @designation_numbers ||= DesignationAccount.joins(:designation_profile_accounts)
                                                 .where(designation_profile_accounts: { designation_profile: designation_profiles })
                                                 .pluck(:designation_number)
    end

    def add_or_update_company(account_list, siebel_donor, donor_account)
      company = fetch_company_from_siebel_donor(account_list, siebel_donor)
      contact = siebel_donor.primary_contact || SiebelDonations::Contact.new
      address = siebel_donor.primary_address || SiebelDonations::Address.new

      company.update!(
        name: siebel_donor.account_name,
        phone_number: contact.primary_phone_number.try(:phone),
        street: fetch_street_from_address(address),
        city: address.city,
        state: address.state,
        postal_code: address.zip
      )

      if company.persisted? && donor_account.master_company == company.master_company
        donor_account.update!(master_company: company.master_company)
      end

      company
    end

    def fetch_company_from_siebel_donor(account_list, siebel_donor)
      master_company = MasterCompany.find_by(name: siebel_donor.account_name)

      company = organization_account.user.partner_companies.find_by(master_company_id: master_company.id) if master_company

      company || account_list.companies.new(master_company: master_company)
    end

    def fetch_street_from_address(address)
      [address.address1, address.address2, address.address3, address.address4].compact.join("\n")
    end

    def add_or_update_donor_account(account_list, siebel_donor)
      donor_account = find_or_initialize_donor_account_from_siebel_donor(siebel_donor)

      donor_account.update!(name: siebel_donor.account_name, donor_type: siebel_donor.type)
      contact = donor_account.link_to_contact_for(account_list)

      save_donor_addresses(siebel_donor, donor_account, contact)
      save_donor_people(siebel_donor, donor_account, contact)

      donor_account
    end

    def save_donor_addresses(siebel_donor, donor_account, contact)
      siebel_donor.addresses&.each do |siebel_address|
        next unless relevant_siebel_address?(siebel_address)

        add_or_update_address(siebel_address, donor_account, contact)
      end
    end

    def relevant_siebel_address?(siebel_address)
      @date_from.nil? || DateTime.parse(siebel_address.updated_at) > @date_from
    end

    def save_donor_people(siebel_donor, donor_account, contact)
      # People are called contacts on siebel
      siebel_donor.contacts&.each do |siebel_person|
        next unless siebel_person_is_relevant?(siebel_person)

        add_or_update_person(siebel_person, donor_account, contact)
      end
    end

    def add_or_update_person(siebel_person, donor_account, contact)
      PersonImporter.new(siebel_import)
                    .add_or_update_person_on_contact(siebel_person: siebel_person,
                                                     donor_account: donor_account,
                                                     contact: contact,
                                                     date_from: @date_from)
    end

    def siebel_person_is_relevant?(siebel_person)
      @date_from.nil? || parse_date(siebel_person.updated_at) > @date_from
    end

    def find_or_initialize_donor_account_from_siebel_donor(siebel_donor)
      organization.donor_accounts.where(account_number: siebel_donor.id).first_or_initialize
    end

    def add_or_update_address(siebel_address, donor_account, contact)
      mpdx_address_instance = mpdx_address_instance_from_siebel_address(siebel_address, donor_account, contact)
      mpdx_address_to_update = find_similar_mpdx_address_from_mpdx_address_instance(mpdx_address_instance, contact)

      if mpdx_address_to_update
        mpdx_address_attributes_needed = mpdx_address_instance.attributes.select { |_k, value| value }

        mpdx_address_to_update.assign_attributes(mpdx_address_attributes_needed)
        mpdx_address_to_update.save!(validate: false)
        mpdx_address_to_update
      else
        contact.addresses.create(mpdx_address_instance.attributes)
      end
    end

    def find_similar_mpdx_address_from_mpdx_address_instance(mpdx_address_instance, contact)
      contact.addresses_including_deleted.find { |address| address.equal_to?(mpdx_address_instance) }
    end

    def mpdx_address_instance_from_siebel_address(siebel_address, donor_account, contact)
      mpdx_address_instance = Address.new(street: [siebel_address.address1, siebel_address.address2, siebel_address.address3, siebel_address.address4].compact.join("\n"),
                                          city: siebel_address.city,
                                          state: siebel_address.state,
                                          postal_code: siebel_address.zip,
                                          primary_mailing_address: should_be_primary?(contact, siebel_address, donor_account),
                                          seasonal: siebel_address.seasonal,
                                          location: siebel_address.type,
                                          remote_id: siebel_address.id,
                                          source: 'Siebel',
                                          start_date: parse_date(siebel_address.updated_at),
                                          source_donor_account: donor_account)

      # Set the master address so we can match by the same address formatted differently
      mpdx_address_instance.find_or_create_master_address

      mpdx_address_instance
    end

    def should_be_primary?(contact, siebel_address, donor_account)
      current_primary_address = contact.addresses.find_by(primary_mailing_address: true)

      current_primary_address.blank? || (siebel_address.primary && current_primary_address.source == 'Siebel' &&
        donor_account.present? && current_primary_address.source_donor_account == donor_account)
    end
  end
end
