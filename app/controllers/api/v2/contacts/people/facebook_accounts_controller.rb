class Api::V2::Contacts::People::FacebookAccountsController < Api::V2Controller
  def index
    authorize load_person, :show?
    load_fb_accounts
    render json: @fb_accounts, meta: meta_hash(@fb_accounts)
  end

  def show
    load_fb_account
    authorize_fb_account
    render_fb_account
  end

  def create
    persist_fb_account
  end

  def update
    load_fb_account
    authorize_fb_account
    persist_fb_account
  end

  def destroy
    load_fb_account
    authorize_fb_account
    @fb_account.destroy
    render_200
  end

  private

  def load_fb_accounts
    @fb_accounts = fb_account_scope.where(filter_params)
                                   .reorder(sorting_param)
                                   .page(page_number_param)
                                   .per(per_page_param)
  end

  def load_fb_account
    @fb_account ||= fb_account_scope.find(params[:id])
  end

  def authorize_fb_account
    authorize @fb_account
  end

  def render_fb_account
    render json: @fb_account
  end

  def persist_fb_account
    build_fb_account
    authorize_fb_account
    return show if save_fb_account
    render_400_with_errors(@fb_account)
  end

  def build_fb_account
    @fb_account ||= fb_account_scope.build
    @fb_account.assign_attributes(fb_account_params)
  end

  def save_fb_account
    @fb_account.save
  end

  def fb_account_params
    params.require(:data).require(:attributes).permit(Person::FacebookAccount::PERMITTED_ATTRIBUTES)
  end

  def fb_account_scope
    load_person.facebook_accounts
  end

  def load_person
    @person ||= load_contact.people.find(params[:person_id])
  end

  def load_contact
    @contact ||= Contact.find(params[:contact_id])
  end

  def permitted_filters
    []
  end

  def pundit_user
    action_name == 'index' ? PunditContext.new(current_user, contact: load_contact) : current_user
  end
end
