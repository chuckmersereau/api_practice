class Api::V1::DonationsController < Api::V1::BaseController
  def index
    order = params[:order] || 'donations.id'

    if params[:contact_id].present?
      donor_account_ids = current_account_list.contacts.find(params[:contact_id]).donor_account_ids
      filtered_donations = current_account_list.donations.where(donor_account_id: donor_account_ids)
    end
    filtered_donations ||= donations

    filtered_donations = add_includes_and_order(filtered_donations, per_page: params[:limit], order: order)
    meta = { total: filtered_donations.total_entries,
             from: correct_from(filtered_donations),
             to: correct_to(filtered_donations),
             page: page,
             total_pages: total_pages(filtered_donations) }

    render json: filtered_donations,
           meta: meta,
           scope: { user: current_user, account_list: current_account_list, locale: locale },
           callback: params[:callback]
  end

  def update
    load_donation
    build_donation
    save_donation
    render json: @donation, scope: { user: current_user, account_list: current_account_list, locale: locale }
  end

  delegate :donations, to: :current_account_list

  protected

  def available_includes
    [:donor_account]
  end

  def load_donation
    @donation ||= donation_scope.find(params[:id])
  end

  def build_donation
    @donation ||= donation_scope.new
    @donation.attributes = donation_params
  end

  def save_donation
    @donation.save
  end

  def donation_scope
    current_account_list.donations
  end

  def donation_params
    return {} unless params[:donation]
    params[:donation].permit(
      :amount, :appeal_amount, :appeal_id, :currency, :designation_account_id,
      :donation_date, :donor_account_id, :motivation, :payment_method
    )
  end
end
