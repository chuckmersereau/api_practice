class Api::V2::Contacts::ReferralsController < Api::V2Controller
  def index
    authorize current_contact, :show?
    load_referrals

    render json: @referrals, meta: meta_hash(@referrals)
  end

  def show
    load_referral
    authorize_referral

    render_referral
  end

  def create
    persist_referral
  end

  def update
    load_referral
    authorize_referral

    persist_referral
  end

  def destroy
    load_referral
    authorize_referral
    destroy_referral
  end

  private

  def current_contact
    @current_contact ||= Contact.find(params[:contact_id])
  end

  def referral_params
    params
      .require(:data)
      .require(:attributes)
      .permit(referral_attributes)
  end

  def referral_attributes
    ContactReferral::PERMITTED_ATTRIBUTES
  end

  def referral_scope
    # This is just a placeholder to remind you to properly scope the model
    # ie: It's meant to blow up :)
    current_contact.contact_referrals_by_me
  end

  def authorize_referral
    authorize @referral
  end

  def build_referral
    @referral ||= referral_scope.build
    @referral.assign_attributes(referral_params)
  end

  def destroy_referral
    @referral.destroy
    head :no_content
  end

  def load_referral
    @referral ||= referral_scope.find(params[:id])
  end

  def load_referrals
    @referrals = referral_scope.where(filter_params)
                               .reorder(sorting_param)
                               .page(page_number_param)
                               .per(per_page_param)
  end

  def persist_referral
    build_referral
    authorize_referral

    if save_referral
      render_referral
    else
      render_400_with_errors(@referral)
    end
  end

  def render_referral
    render json: @referral,
           status: success_status
  end

  def save_referral
    @referral.save
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end
end
