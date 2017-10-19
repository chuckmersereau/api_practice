class Api::V2::Coaching::PledgesController < Api::V2Controller
  resource_type :pledges

  def index
    load_pledges
    render json: @pledges.preload_valid_associations(include_associations),
           meta: meta_with_totals_hash(@pledges),
           include: include_params,
           fields: field_params,
           each_serializer: ::Coaching::PledgeSerializer
  end

  def show
    load_pledge
    authorize_pledge
    render_pledge
  end

  private

  def load_pledges
    @pledges =
      ::Coaching::Pledge::Filterer.new(filter_params)
                                  .filter(scope: pledges_scope,
                                          account_lists: account_lists)
                                  .reorder(sorting_param)
                                  .page(page_number_param)
                                  .per(per_page_param)
  end

  def pledges_scope
    current_user.becomes(User::Coach).coaching_pledges
  end

  def load_pledge
    @pledge ||= Pledge.find_by_uuid_or_raise!(params[:id])
  end

  def authorize_pledge
    authorize @pledge
  end

  def render_pledge
    render json: @pledge,
           status: success_status,
           include: include_params,
           fields: field_params,
           serializer: ::Coaching::PledgeSerializer
  end

  def permitted_sorting_params
    %w(amount expected_date)
  end

  def permitted_filters
    ::Coaching::Pledge::Filterer::FILTERS_TO_DISPLAY.map(&:underscore)
                                                    .map(&:to_sym)
  end

  def meta_with_totals_hash(scope)
    service =
      Coaching::Pledge::TotalMonthlyPledge.new(
        scope, current_user&.default_account_list_record&.default_currency
      )

    meta = meta_hash(scope)
    meta[:total_pledge] = { amount: service.total, currency: service.currency }
    meta
  end
end
