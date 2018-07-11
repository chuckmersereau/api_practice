class Api::V2::DeletedRecordsController < Api::V2Controller
  def index
    authorize_index
    format_since_date
    @deleted_records = filter_deleted_records.reorder(sorting_param)
                                             .order(default_sort_param)
                                             .page(page_number_param)
                                             .per(per_page_param)
    render json: @deleted_records.preload_valid_associations(include_associations),
           meta: meta_hash(@deleted_records),
           include: include_params,
           fields: field_params
  end

  private

  # The current filter will change a date to a datetime range, with the end date set to
  # the end of the day, of the date, which will not work for a simple +since_date+. So,
  # we'll do an early detection and put today's date as the end date, if needed.
  def format_since_date
    return unless params[:filter] && params[:filter][:since_date]
    params[:filter][:since_date] += "..#{1.day.from_now.utc.iso8601}" unless params[:filter][:since_date].include?('..')
  end

  def filter_deleted_records
    DeletedRecords::Filterer.new(filter_params).filter(scope: deleted_records_scope, account_lists: account_lists)
  end

  def deleted_records_scope
    DeletedRecord.where(deleted_from_id: deleted_from_ids)
  end

  def deleted_from_ids
    account_lists.map(&:id) + designation_account_ids
  end

  def designation_account_ids
    @designation_account_ids ||= AccountListEntry.where(account_list_id: account_lists.map(&:id)).distinct.pluck(:designation_account_id)
  end

  def authorize_index
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end

  def permitted_filters
    [:account_list_id, :since_date, :types]
  end
end
