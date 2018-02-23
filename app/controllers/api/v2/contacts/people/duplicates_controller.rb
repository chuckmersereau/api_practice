class Api::V2::Contacts::People::DuplicatesController < Api::V2Controller
  resource_type :duplicate_record_pairs

  def index
    authorize_index
    find_more_duplicates
    load_duplicates
    render_duplicates
  end

  def show
    load_duplicate
    authorize_duplicate
    render_duplicate
  end

  def update
    load_duplicate
    authorize_duplicate
    persist_duplicate
  end

  private

  def authorize_index
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end

  def authorize_duplicate
    @duplicate.records.each { |person| authorize(person, :update?) }
    authorize(@duplicate.account_list, :update?)
  end

  def duplicates_scope
    DuplicateRecordPair.type('Person').where(account_list: account_lists)
  end

  def find_more_duplicates
    account_lists.each do |account_list|
      Person::DuplicatePairsFinder.new(account_list).find_and_save
    end
  end

  def load_duplicates
    @duplicates = duplicates_scope.where(filter_params)
                                  .reorder(sorting_param)
                                  .order(:created_at)
                                  .page(page_number_param)
                                  .per(per_page_param)
  end

  def load_duplicate
    @duplicate = DuplicateRecordPair.type('Person').find_by!(id: params[:id])
  end

  def build_duplicate
    @duplicate ||= DuplicateRecordPair.new(type: 'Person')
    @duplicate.assign_attributes(duplicate_params)
  end

  def save_duplicate
    @duplicate.save(context: persistence_context)
  end

  def persist_duplicate
    build_duplicate
    authorize_duplicate

    if save_duplicate
      render_duplicate
    else
      render_with_resource_errors(@duplicate)
    end
  end

  def duplicate_params
    params.require(:duplicate_record_pair)
          .permit(DuplicateRecordPair::PERMITTED_ATTRIBUTES)
  end

  def render_duplicate
    render json: @duplicate,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def render_duplicates
    render json: @duplicates,
           meta: meta_hash(@duplicates),
           include: include_params,
           fields: field_params
  end

  def permitted_filters
    [:account_list_id, :ignore]
  end

  def pundit_user
    PunditContext.new(current_user)
  end
end
