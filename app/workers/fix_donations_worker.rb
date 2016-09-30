require './dev/migrate/2016_07_14_fix_donations_without_designation_acc.rb'
class FixDonationsWorker
  include Sidekiq::Worker

  def perform(offset = 0)
    AddAccountsToDonations.new.add_accounts_to_donations(offset)
  end
end
