class Api::V2::AccountLists::DonationsController < Api::V2Controller
  def index
    authorize load_account_list, :show?
    load_donations
    render json: @donations,
           scope: { account_list: load_account_list, locale: locale },
           meta: meta_hash(@donations)
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

  private

  def load_donations
    @donations = donation_scope.where(filter_params)
                               .reorder(sorting_param)
                               .page(page_number_param)
                               .per(per_page_param)
  end

  def load_donation
    @donation ||= Donation.find(params[:id])
  end

  def render_donation
    render json: @donation, scope: { account_list: load_account_list, locale: locale }
  end

  def persist_donation
    build_donation
    authorize_donation
    return show if save_donation
    render_400_with_errors(@donation)
  end

  def build_donation
    @donation ||= donation_scope.build
    @donation.assign_attributes(donation_params)
  end

  def authorize_donation
    authorize @donation
  end

  def save_donation
    @donation.save
  end

  def donation_params
    params.require(:data).require(:attributes).permit(Donation::PERMITTED_ATTRIBUTES)
  end

  def donation_scope
    load_account_list.donations
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permitted_filters
    []
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
