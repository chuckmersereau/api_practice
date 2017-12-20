class DonationAmountRecommendation::RemoteWorker
  include Sidekiq::Worker
  sidekiq_options queue: :api_donation_amount_recommendation_remote_worker

  def perform
    import_donation_amount_recommendations
    delete_old_donation_amount_records
  end

  private

  def import_donation_amount_recommendations
    per_page = 1000.0
    pages = (DonationAmountRecommendation::Remote.count / per_page).ceil
    pages.times do |page|
      # we must re-order because created_at will return the current time, making it indeterminate
      # n.times starts at 0, but we want pages with 1 base
      DonationAmountRecommendation::Remote.reorder(:started_at)
                                          .page(page + 1)
                                          .per(per_page)
                                          .each(&method(:process_remote_recommendation))
    end
  end

  def process_remote_recommendation(remote)
    return unless remote.organization && remote.designation_account && remote.donor_account
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

  def delete_old_donation_amount_records
    DonationAmountRecommendation.where('updated_at <= ?', 12.hours.ago).delete_all
  end
end
