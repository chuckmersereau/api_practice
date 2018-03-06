class Api::V2::Contacts::ReferrersController < Api::V2Controller
  def index
    authorize_index
    load_referrers
    render_referrers
  end

  private

  def current_contact
    @contact ||= Contact.find(params[:contact_id])
  end

  def referrer_scope
    current_contact.contacts_that_referred_me
  end

  def authorize_index
    authorize(current_contact, :show?)
  end

  def load_referrers
    @referrers = referrer_scope.where(filter_params)
                               .reorder(sorting_param)
                               .order(:created_at)
                               .page(page_number_param)
                               .per(per_page_param)
  end

  def render_referrers
    render json: @referrers.preload_valid_associations(include_associations),
           meta: meta_hash(@referrers),
           include: include_params,
           fields: field_params
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end
end
