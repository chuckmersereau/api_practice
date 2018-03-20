class ChangeCollationOfContactsNameColumn < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute(
      'ALTER TABLE contacts ALTER name TYPE character varying COLLATE "C";'
    )
  end

  def down
    ActiveRecord::Base.connection.execute(
      'ALTER TABLE contacts ALTER name TYPE character varying COLLATE "en_US.UTF-8";'
    )
  end
end
