class ReAddIndexes < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    indexes = CSV.read(Rails.root.join('db','dropped_indexes.csv'), headers: true)

    indexes.each do |index_row|
      execute index_row['indexdef'].sub('INDEX', 'INDEX CONCURRENTLY')
    end
  end
end
