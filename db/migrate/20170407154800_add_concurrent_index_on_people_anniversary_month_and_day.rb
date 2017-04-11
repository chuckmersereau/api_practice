class AddConcurrentIndexOnPeopleAnniversaryMonthAndDay < ActiveRecord::Migration
  # Line added for concurrency,
  # see: https://robots.thoughtbot.com/how-to-create-postgres-indexes-concurrently-in
  disable_ddl_transaction!

  def change
    add_index :people, :anniversary_day,   algorithm: :concurrently
    add_index :people, :anniversary_month, algorithm: :concurrently
  end
end
