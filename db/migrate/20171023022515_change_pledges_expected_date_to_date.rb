class ChangePledgesExpectedDateToDate < ActiveRecord::Migration
	def change
		reversible do |dir|
			dir.up   { change_column :pledges, :expected_date, :date }
			dir.down { change_column :pledges, :expected_date, :datetime }
		end
	end
end
