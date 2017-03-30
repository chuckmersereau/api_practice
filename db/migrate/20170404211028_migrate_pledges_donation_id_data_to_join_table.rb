class MigratePledgesDonationIdDataToJoinTable < ActiveRecord::Migration
  def up
    Pledge.where.not(donation_id: nil).find_each do |pledge|
      PledgeDonation.create(donation_id: pledge.donation_id, pledge_id: pledge.id)
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
