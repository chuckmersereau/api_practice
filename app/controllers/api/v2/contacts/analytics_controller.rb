class Api::V2::Contacts::AnalyticsController < Api::V2Controller
  def show
    load_analytics
    authorize_analytics
    render_analytics
  end

  private

  def account_list
    @account_list ||= load_account_list
  end

  def authorize_analytics
    if account_list
      authorize account_list, :show?
    else
      authorize current_user, :show?
    end
  end

  def load_account_list
    return unless filter_params[:account_list_id]

    AccountList.find(filter_params[:account_list_id])
  end

  def load_analytics
    @analytics ||= Contact::Analytics.new(load_contacts)
  end

  def load_contacts
    account_list&.contacts || current_user.contacts
  end

  def permitted_filters
    [:account_list_id]
  end

  def render_analytics
    render json: @analytics,
           include: include_params,
           fields: field_params
  end
end
