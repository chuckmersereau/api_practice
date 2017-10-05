class ConvertPledgeStateFieldsToEnum < ActiveRecord::Migration
  class PledgeForMigration < ActiveRecord::Base
    self.table_name = 'pledges'
  end

  def up
    add_column(:pledges, :status, :string, default: 'not_received')
    PledgeForMigration.where(received_not_processed: true).update_all(status: 'received_not_processed')
    PledgeForMigration.where(processed: true).update_all(status: 'processed')
    remove_column(:pledges, :processed)
    remove_column(:pledges, :received_not_processed)
  end

  def down
    add_column(:pledges, :processed, :boolean, default: false)
    add_column(:pledges, :received_not_processed, :boolean, default: false)
    PledgeForMigration.where(status: 'received_not_processed').update_all(received_not_processed: true)
    PledgeForMigration.where(status: 'processed').update_all(processed: true)
    remove_column(:pledges, :status)
  end
end
