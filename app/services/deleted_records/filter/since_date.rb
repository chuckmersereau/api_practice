class DeletedRecords::Filter::SinceDate < ApplicationFilter
  def execute_query(deleted_records, filters)
    return deleted_records if filters[:since_date].blank?
    deleted_records.between_dates(filters[:since_date])
  end
end
