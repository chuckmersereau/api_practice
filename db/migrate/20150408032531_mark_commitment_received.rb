class MarkCommitmentReceived < ActiveRecord::Migration
  def change
    Contact.where({status: 'Partner - Financial', pledge_received: false}).joins(:donor_accounts).find_each(batch_size: 500) do |contact|
      last_donation = contact.donations.order(:donation_date).first
      next unless last_donation
      giving_window = 2.months.ago if contact.pledge_frequency.blank? || contact.pledge_frequency < 1
      giving_window ||= (contact.pledge_frequency * 2).to_i.months.ago
      next if last_donation.donation_date < giving_window
      contact.update_attribute(:pledge_received, true)
    end
  end
end
