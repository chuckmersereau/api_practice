class Api::V2::Coaching::ContactsController < Api::V2Controller
  resource_type :contacts

  def index
    load_contacts
    render json: @contacts.preload_valid_associations(include_associations),
           meta: meta_with_totals_hash(@contacts),
           include: include_params,
           fields: field_params,
           each_serializer: Coaching::ContactSerializer
  end

  def show
    load_contact
    authorize_contact
    render_contact
  end

  private

  def load_contacts
    @contacts =
      ::Coaching::Contact::Filterer.new(filter_params)
                                   .filter(scope: contacts_scope,
                                           account_lists: account_lists)
                                   .reorder(sorting_param)
                                   .order(default_sort_param)
                                   .page(page_number_param)
                                   .per(per_page_param)
  end

  def contacts_scope
    current_user.becomes(User::Coach).coaching_contacts
  end

  def load_contact
    @contact ||= Contact.find(params[:id])
  end

  def authorize_contact
    authorize @contact
  end

  def render_contact
    render json: @contact,
           status: success_status,
           include: include_params,
           fields: field_params,
           serializer: Coaching::ContactSerializer
  end

  def permitted_sorting_params
    %w(name)
  end

  def default_sort_param
    Contact.arel_table[:created_at].asc
  end

  def permitted_filters
    ::Coaching::Contact::Filterer::FILTERS_TO_DISPLAY.map(&:underscore)
                                                     .map(&:to_sym)
  end

  def meta_with_totals_hash(scope)
    service =
      Coaching::Contact::TotalMonthlyPledge.new(
        scope, current_user&.default_account_list_record&.default_currency
      )

    meta = meta_hash(scope)
    meta[:total_pledge] = { amount: service.total, currency: service.currency }
    meta
  end
end
