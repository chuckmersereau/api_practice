class ReAddIndexes < ActiveRecord::Migration
  disable_ddl_transaction!

  def up
    # we don't want running this to prevent production from starting
    return if Rails.env.production? || Rails.env.staging?

    path = Rails.root.join('db','dropped_indexes.csv')

    CSV.read(path, headers: true).each do |index_row|
      execute index_row['indexdef'].sub('INDEX', 'INDEX CONCURRENTLY IF NOT EXISTS')
    end
  end
end
