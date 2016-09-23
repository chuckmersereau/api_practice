require './dev/migrate/2016_07_14_fix_donations_without_designation_acc.rb'
class FixDonationsWorker
	include Sidekiq::Worker
	def perform
		AddAccountsToDonations.new.add_accounts_to_donations
	end
end