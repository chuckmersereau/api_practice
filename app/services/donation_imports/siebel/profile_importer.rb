class DonationImports::Siebel
  # This class imports designation profiles associated to a Siebel organization account.

  class ProfileImporter
    attr_accessor :siebel_import, :organization, :organization_account

    def initialize(siebel_import)
      @siebel_import = siebel_import
      @organization = siebel_import.organization
      @organization_account = siebel_import.organization_account
    end

    def import_profiles
      siebel_profiles.each do |siebel_profile|
        designation_profile = find_or_create_designation_profile(siebel_profile)

        add_included_designation_accounts(designation_profile, siebel_profile)

        import_profile_balance(designation_profile)

        link_account_list(designation_profile) unless designation_profile.account_list
      end

      true
    end

    private

    def siebel_profiles
      @siebel_profiles ||= fetch_siebel_profiles
    end

    def fetch_siebel_profiles
      return try_to_get_siebel_profiles if organization_account_is_valid?

      organization_account.destroy
      []
    end

    def try_to_get_siebel_profiles
      set_relay_id_from_key_account unless organization_account.remote_id

      Retryable.retryable on: RestClient::InternalServerError do
        SiebelDonations::Profile.find(ssoGuid: organization_account.remote_id)
      end
    end

    def set_relay_id_from_key_account
      organization_account.update(remote_id: organization_account.user.key_accounts.pluck(:relay_remote_id).first)

      organization_account.reload
    end

    def organization_account_is_valid?
      organization_account.user.relay_accounts.any?
    end

    def link_account_list(designation_profile)
      AccountList::FromProfileLinker.new(designation_profile, organization_account).link_account_list!
    end

    def add_included_designation_accounts(designation_profile, siebel_profile)
      siebel_profile.designations.each do |designation|
        find_or_create_designation_account(designation.number,
                                           designation_profile,
                                           name: designation.description,
                                           staff_account_id: designation.staff_account_id,
                                           chartfield: designation.chartfield)
      end
    end

    def find_or_create_designation_profile(siebel_profile)
      organization.designation_profiles.where(user_id: organization_account.person_id, code: siebel_profile.id)
                  .first_or_create(name: siebel_profile.name)
    end

    def import_profile_balance(designation_profile)
      balance_total = designation_profile.designation_accounts.to_a.sum do |designation_account|
        balance_amount_from_designation_account(designation_account).to_f
      end

      designation_profile.update!(balance: balance_total, balance_updated_at: Time.now)
    end

    def balance_amount_from_designation_account(designation_account)
      return unless designation_account.staff_account_id

      balance_object = SiebelDonations::Balance.find(employee_ids: designation_account.staff_account_id).first
      balance_amount = balance_object.primary if designation_account.active?

      designation_account.update!(balance: balance_amount.to_f, balance_updated_at: Time.now)

      balance_amount
    end

    def find_or_create_designation_account(designation_number, designation_profile, extra_attributes = {})
      designation_account = find_or_create_designation_account_by_number(designation_number)

      designation_profile.designation_accounts << designation_account unless designation_profile.designation_accounts.include?(designation_account)
      designation_account.update_attributes!(extra_attributes) if extra_attributes.present?

      designation_account.reload
    end

    def find_or_create_designation_account_by_number(designation_number)
      organization.designation_accounts.where(designation_number: designation_number).first_or_create
    end
  end
end
