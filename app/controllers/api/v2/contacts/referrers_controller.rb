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
    current_contact.referrals_to_me
  end

  def authorize_index
    authorize(current_contact, :show?)
  end

  def load_referrers
    @referrers = referrer_scope.reorder(sorting_param)
                               .page(page_number_param)
                               .per(per_page_param)
  end

  def render_referrers
    render json: @referrers, meta: meta_hash(@referrers)
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end
end
