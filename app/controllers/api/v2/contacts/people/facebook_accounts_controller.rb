class Api::V2::Contacts::People::FacebookAccountsController < Api::V2Controller
  def index
    authorize load_person, :show?
    load_fb_accounts
    render json: @fb_accounts.preload_valid_associations(include_associations),
           meta: meta_hash(@fb_accounts),
           include: include_params,
           fields: field_params
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
    destroy_fb_account
  end

  private

  def destroy_fb_account
    @fb_account.destroy
    head :no_content
  end

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
    render json: @fb_account,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_fb_account
    build_fb_account
    authorize_fb_account

    if save_fb_account
      render_fb_account
    else
      render_with_resource_errors(@fb_account)
    end
  end

  def build_fb_account
    @fb_account ||= fb_account_scope.build
    @fb_account.assign_attributes(fb_account_params)
  end

  def save_fb_account
    @fb_account.save(context: persistence_context)
  end

  def fb_account_params
    params.require(:facebook_account)
          .permit(Person::FacebookAccount::PERMITTED_ATTRIBUTES)
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

  def pundit_user
    action_name == 'index' ? PunditContext.new(current_user, contact: load_contact) : current_user
  end
end
