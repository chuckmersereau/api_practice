class Api::V2::Contacts::People::LinkedinAccountsController < Api::V2Controller
  def index
    authorize load_person, :show?
    load_linkedin_accounts
    render json: @linkedin_accounts, meta: meta_hash(@linkedin_accounts), include: include_params
  end

  def show
    load_linkedin_account
    authorize_linkedin_account
    render_linkedin_account
  end

  def create
    persist_linkedin_account
  end

  def update
    load_linkedin_account
    authorize_linkedin_account
    persist_linkedin_account
  end

  def destroy
    load_linkedin_account
    authorize_linkedin_account
    destroy_linkedin_account
  end

  private

  def destroy_linkedin_account
    @linkedin_account.destroy
    head :no_content
  end

  def load_linkedin_accounts
    @linkedin_accounts = linkedin_account_scope.where(filter_params)
                                               .reorder(sorting_param)
                                               .page(page_number_param)
                                               .per(per_page_param)
  end

  def load_linkedin_account
    @linkedin_account ||= linkedin_account_scope.find_by!(uuid: params[:id])
  end

  def authorize_linkedin_account
    authorize @linkedin_account
  end

  def render_linkedin_account
    render json: @linkedin_account,
           status: success_status,
           include: include_params
  end

  def persist_linkedin_account
    build_linkedin_account
    authorize_linkedin_account

    if save_linkedin_account
      render_linkedin_account
    else
      render_400_with_errors(@linkedin_account)
    end
  end

  def build_linkedin_account
    @linkedin_account ||= linkedin_account_scope.build
    @linkedin_account.assign_attributes(linkedin_account_params)
  end

  def save_linkedin_account
    @linkedin_account.save
  end

  def linkedin_account_params
    params.require(:data).require(:attributes).permit(Person::LinkedinAccount::PERMITTED_ATTRIBUTES)
  end

  def linkedin_account_scope
    load_person.linkedin_accounts
  end

  def load_person
    @person ||= load_contact.people.find_by!(uuid: params[:person_id])
  end

  def load_contact
    @contact ||= Contact.find_by!(uuid: params[:contact_id])
  end

  def permitted_filters
    []
  end

  def pundit_user
    action_name == 'index' ? PunditContext.new(current_user, contact: load_contact) : current_user
  end
end
