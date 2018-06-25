class DeletedRecords::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w(Types SinceDate).freeze
end
