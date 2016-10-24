class Api::V1::DonorAccountsController < Api::V1::BaseController
  def index
    load_donor_accounts
    render json: @donor_accounts,
           scope: { user: current_user, account_list: current_account_list, locale: locale },
           callback: params[:callback],
           each_serializer: DonorAccountSerializer
  end

  protected

  def load_donor_accounts
    @donor_accounts ||= donor_account_scope.sort_by(&:name)
  end

  def donor_account_scope
    current_account_list.contacts.active.joins(:donor_accounts).includes(:donor_accounts).map(&:donor_accounts).flatten.uniq
  end
end
