class Api::V2::Contacts::AnalyticsController < Api::V2Controller
  def show
    load_analytics
    authorize_analytics
    render_analytics
  end

  private

  def authorize_analytics
    account_lists.each { |account_list| authorize account_list, :show? }
  end

  def load_analytics
    @analytics ||= Contact::Analytics.new(load_contacts)
  end

  def load_contacts
    Contact.where(account_list: account_lists.map(&:id))
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
