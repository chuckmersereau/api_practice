# This class looks for a donation that already exists in MPDX to match to a donation that is being imported.
# We don't want to import a donation more than once into the same designation profile.
# The attributes passed on initialize will be considered authoritative.

class DonationImports::Base
  class FindDonation
    attr_accessor :designation_profile, :attributes

    def initialize(designation_profile:, attributes:)
      @designation_profile = designation_profile
      @attributes = attributes.with_indifferent_access
    end

    def find_and_merge
      donations = find_donations_by_remote_id # First look for the donation by it's remote id or Tnt id.

      if donations.empty?
        # If the donation couldn't be found by it's id look for it by it's other attributes.
        # One way this could happen is if the donation was imported
        # from Tnt before we started storing the tnt_id.
        donations = find_donations_by_donor_and_amount_and_date
      end

      # The donation may have ended up in the incorrect designation account, or in multiple
      # designation accounts (duplicated). One way this could happen is because the Tnt import
      # does not know which designation account to put it in, so it makes up a new one.
      # Since we now know the correct designation account (in attributes)
      # we will correct the error by running a merge process.
      MergeDonations.new(donations).merge
    end

    private

    def find_donations_by_remote_id
      return [] if attributes[:remote_id].blank?
      donation_scope.where('tnt_id = :id OR remote_id = :id', id: attributes[:remote_id]).to_a
    end

    def find_donations_by_donor_and_amount_and_date
      where_fields = attributes.slice(:donor_account_id, :amount, :donation_date).merge(remote_id: nil)
      donation_scope.where(where_fields).to_a
    end

    def donation_scope
      Donation.where(designation_account_id: searchable_designation_ids)
    end

    # because the DesignationAccount created when the user imports from Tnt was created
    # un-associated to a DesignationProfile, we need to also look at those 'placeholder' accounts
    def searchable_designation_ids
      profile_accounts = designation_profile.designation_accounts.pluck(:id)
      # include specified designation if account is specified
      profile_accounts = (profile_accounts + [attributes[:designation_account_id]]).compact.uniq

      account_list = designation_profile.account_list
      return profile_accounts unless account_list
      placeholder_accounts = account_list.designation_accounts.where(designation_number: nil).pluck(:id)

      profile_accounts + placeholder_accounts
    end
  end
end
