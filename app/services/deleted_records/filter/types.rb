class DeletedRecords::Filter::Types < ApplicationFilter
  def execute_query(deleted_records, filters)
    return deleted_records if filters[:types].blank?
    deleted_records.where(deletable_type: parse_list(filters[:types]))
  end
end
