class DeletedRecords::Filterer < ApplicationFilterer
  FILTERS_TO_DISPLAY = %w(SinceDate Types).freeze
end
