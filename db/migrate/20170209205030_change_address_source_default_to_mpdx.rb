class ChangeAddressSourceDefaultToMpdx < ActiveRecord::Migration
  def up
    change_column :addresses, :source, :string, default: 'MPDX'
  end

  def down
    change_column :addresses, :source, :string, default: nil
  end
end
