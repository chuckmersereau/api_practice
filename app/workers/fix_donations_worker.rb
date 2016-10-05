require './dev/migrate/2016_07_14_fix_donations_without_designation_acc.rb'
class FixDonationsWorker
  include Sidekiq::Worker

  def perform(last_donor_id = 0)
    AddAccountsToDonations.new.add_accounts_to_donations(last_donor_id)
  end
end
