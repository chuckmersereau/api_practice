class AddDefaultMpdxToExistingAddressSource < ActiveRecord::Migration
  def up
    Address.where(source: ['manual', nil]).update_all(source: 'MPDX')
  end

  def down
    Address.where(source: 'MPDX').update_all(source: nil)
  end
end
