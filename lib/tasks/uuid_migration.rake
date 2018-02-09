namespace :mpdx do
  task readd_indexes: :environment do
    path = Rails.root.join('db', 'dropped_indexes.csv')

    raise "indexes file doesn't exist!" unless File.exist?(path)

    CSV.read(path, headers: true).each do |index_row|
      puts "attempting to add index: #{index_row['indexname']}"
      ActiveRecord::Base.connection.execute index_row['indexdef'].sub('INDEX', 'INDEX CONCURRENTLY IF NOT EXISTS')
    end
  end
end
