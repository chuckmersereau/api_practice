class DonationImports::Siebel
  class DonationImporter
    # Donations should sometimes be deleted if they were misclassifed and then
    # later correctly re-classified. However, we have had 2 recent occasions when
    # the Siebel API incorectly returned no donations (or a lot fewer than
    # expected) and it caused MPDX users to unexpectedly lose bunches of
    # donations. So as a safety measure for that only remove a few donations per
    # import as typically only a couple at most will be misclassified.
    MAX_DONATIONS_TO_DELETE_AT_ONCE = 3

    attr_reader :siebel_import

    delegate :organization,
             :organization_account,
             to: :siebel_import

    delegate :designation_profiles, to: :organization_account

    def initialize(siebel_import)
      @siebel_import = siebel_import
    end

    def import_donations(start_date: nil, end_date: nil)
      @start_date = (start_date || organization.minimum_gift_date || Date.new(2004, 1, 1)).strftime('%Y-%m-%d')
      @end_date = (end_date || Time.now).strftime('%Y-%m-%d')

      designation_profiles.each do |designation_profile|
        import_donations_by_designation_profile(designation_profile)
      end

      true
    end

    private

    def import_donations_by_designation_profile(designation_profile)
      siebel_donations_by_designation_profile(designation_profile).each do |siebel_donation|
        add_or_update_mpdx_donation(siebel_donation, designation_profile)
      end

      remove_deleted_siebel_donations(designation_profile)
    end

    def remove_deleted_siebel_donations(designation_profile)
      # Sometimes the Siebel API flakes out and doesn't return any donations.
      # When that happened before it would cause all MPDX's donation records to
      # be destroyed (for Cru USA users). As a sanity check for that flaky API
      # condition, don't remove any donations if there are no donations in the
      # range we are checking (past 50 days typically).

      relevant_mpdx_donations = Donation.joins(:designation_account)
                                        .where(designation_account: designation_profile.designation_accounts)
                                        .where('donation_date >= ? AND donation_date <= ?', @start_date, @end_date)
                                        .where.not(remote_id: nil)

      remove_maximum_number_of_relevant_mpdx_donations(designation_profile, relevant_mpdx_donations)
    end

    def remove_maximum_number_of_relevant_mpdx_donations(designation_profile, relevant_mpdx_donations)
      # We are removing mpdx donations which have a remote_id but are no longer on Siebel
      donations_destroyed = 0

      relevant_mpdx_donations.each do |mpdx_donation|
        break if donations_destroyed == MAX_DONATIONS_TO_DELETE_AT_ONCE

        next if mpdx_donation.appeal.present?
        next if find_siebel_donation_by_mpdx_donation(designation_profile, mpdx_donation)

        mpdx_donation.destroy

        donations_destroyed += 1
      end
    end

    def find_siebel_donation_by_mpdx_donation(designation_profile, mpdx_donation)
      siebel_donations_by_designation_profile(designation_profile).find do |siebel_donation|
        siebel_donation.id == mpdx_donation.remote_id
      end
    end

    def siebel_donations_by_designation_profile(designation_profile)
      @siebel_donations_by_designation_profile ||= {}

      @siebel_donations_by_designation_profile[designation_profile.id] ||=
        fetch_siebel_donations_by_designation_profile(designation_profile)
    end

    def fetch_siebel_donations_by_designation_profile(designation_profile)
      designation_profile.designation_accounts.pluck(:designation_number).map do |designation_number|
        SiebelDonations::Donation.find(posted_date_start: @start_date,
                                       posted_date_end: @end_date,
                                       designations: designation_number)
      end.flatten
    end

    def add_or_update_mpdx_donation(siebel_donation, designation_profile)
      default_currency = organization.default_currency_code || 'USD'
      donor_account = organization.donor_accounts.find_by(account_number: siebel_donation.donor_id)

      designation_account = designation_profile.designation_accounts.find_by(designation_number: siebel_donation.designation)
      mpdx_donation = designation_account.donations.where(remote_id: siebel_donation.id).first_or_initialize

      mpdx_donation.update!(
        donor_account_id: donor_account.id,
        motivation: siebel_donation.campaign_code,
        payment_method: siebel_donation.payment_method,
        tendered_currency: default_currency,
        donation_date: siebel_donation.donation_date.to_date,
        amount: siebel_donation.amount,
        tendered_amount: siebel_donation.amount,
        currency: default_currency,
        channel: siebel_donation.channel,
        payment_type: siebel_donation.payment_type
      )
    end
  end
end
