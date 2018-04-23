class Api::V2::AccountLists::DonationsController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_donations
    render json: @donations.preload(include_associations.except(:contact)),
           scope: { account_list: load_account_list, locale: locale },
           meta: meta_hash(@donations),
           include: include_params,
           fields: field_params
  end

  def show
    load_donation
    authorize_donation
    render_donation
  end

  def create
    persist_donation
  end

  def update
    load_donation
    authorize_donation
    persist_donation
  end

  def destroy
    load_donation
    authorize_donation
    destroy_donation
  end

  private

  def destroy_donation
    @donation.destroy
    head :no_content
  end

  def load_donations
    @donations = donation_scope.where(filter_params)
                               .reorder(sorting_param)
                               .order(default_sort_param)
                               .page(page_number_param)
                               .per(per_page_param)
  end

  def load_donation
    @donation ||= Donation.find(params[:id])
  end

  def render_donation
    render json: @donation,
           scope: { account_list: load_account_list, locale: locale },
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_donation
    build_donation
    authorize_donation

    if save_donation
      render_donation
    else
      render_with_resource_errors(@donation)
    end
  end

  def build_donation
    @donation ||= donation_scope.build
    @donation.assign_attributes(donation_params)
  end

  def authorize_donation
    authorize @donation
  end

  def save_donation
    @donation.save(context: persistence_context)
  end

  def donation_params
    params
      .require(:donation)
      .permit(Donation::PERMITTED_ATTRIBUTES)
  end

  def donation_scope
    load_account_list.donations
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permitted_filters
    [:donor_account_id, :donation_date, :designation_account_id]
  end

  def permitted_sorting_params
    %w(donation_date)
  end

  def default_sort_param
    Donation.arel_table[:created_at].asc
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
