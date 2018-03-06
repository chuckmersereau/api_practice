class Api::V2::Contacts::DonationAmountRecommendationsController < Api::V2Controller
  def index
    authorize current_contact, :show?
    load_donation_amount_recommendations

    render json: @donation_amount_recommendations.preload_valid_associations(include_associations),
           meta: meta_hash(@donation_amount_recommendations),
           include: include_params,
           fields: field_params
  end

  def show
    load_donation_amount_recommendation
    authorize_donation_amount_recommendation

    render_donation_amount_recommendation
  end

  private

  def current_contact
    @current_contact ||= Contact.find(params[:contact_id])
  end

  def donation_amount_recommendation_scope
    current_contact.donation_amount_recommendations
  end

  def authorize_donation_amount_recommendation
    authorize @donation_amount_recommendation
  end

  def load_donation_amount_recommendation
    @donation_amount_recommendation ||= donation_amount_recommendation_scope.find(params[:id])
  end

  def load_donation_amount_recommendations
    @donation_amount_recommendations = donation_amount_recommendation_scope.where(filter_params)
                                                                           .reorder(sorting_param)
                                                                           .order(:created_at)
                                                                           .page(page_number_param)
                                                                           .per(per_page_param)
  end

  def render_donation_amount_recommendation
    render json: @donation_amount_recommendation,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end
end
