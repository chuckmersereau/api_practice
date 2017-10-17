class DonationAmountRecommendation::RemoteWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_donation_amount_recommendation_remote_worker

  def perform
    import_donation_amount_recommendations
    delete_old_donation_amount_records
  end

  private

  def import_donation_amount_recommendations
    DonationAmountRecommendation::Remote.find_each do |remote|
      next unless remote.organization && remote.designation_account && remote.donor_account
      DonationAmountRecommendation.find_or_initialize_by(
        designation_account: remote.designation_account,
        donor_account: remote.donor_account
      ).update(
        ask_at: remote.ask_at,
        started_at: remote.started_at,
        suggested_pledge_amount: remote.suggested_pledge_amount,
        updated_at: Time.now
      )
    end
  end

  def delete_old_donation_amount_records
    DonationAmountRecommendation.where('updated_at <= ?', 12.hours.ago).delete_all
  end
end
