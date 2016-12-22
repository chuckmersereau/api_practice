class Api::V2::Contacts::People::TwitterAccountsController < Api::V2Controller
  def index
    authorize load_person, :show?
    load_twitter_accounts
    render json: @twitter_accounts, meta: meta_hash(@twitter_accounts), include: include_params, fields: field_params
  end

  def show
    load_twitter_account
    authorize_twitter_account
    render_twitter_account
  end

  def create
    persist_twitter_account
  end

  def update
    load_twitter_account
    authorize_twitter_account
    persist_twitter_account
  end

  def destroy
    load_twitter_account
    authorize_twitter_account
    destroy_twitter_account
  end

  private

  def destroy_twitter_account
    @twitter_account.destroy
    head :no_content
  end

  def load_twitter_accounts
    @twitter_accounts = twitter_account_scope.where(filter_params)
                                             .reorder(sorting_param)
                                             .page(page_number_param)
                                             .per(per_page_param)
  end

  def load_twitter_account
    @twitter_account ||= twitter_account_scope.find_by!(uuid: params[:id])
  end

  def authorize_twitter_account
    authorize @twitter_account
  end

  def render_twitter_account
    render json: @twitter_account,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_twitter_account
    build_twitter_account
    authorize_twitter_account

    if save_twitter_account
      render_twitter_account
    else
      render_400_with_errors(@twitter_account)
    end
  end

  def build_twitter_account
    @twitter_account ||= twitter_account_scope.build
    @twitter_account.assign_attributes(twitter_account_params)
  end

  def save_twitter_account
    @twitter_account.save(context: persistence_context)
  end

  def twitter_account_params
    params.require(:data).require(:attributes).permit(Person::TwitterAccount::PERMITTED_ATTRIBUTES)
  end

  def twitter_account_scope
    load_person.twitter_accounts
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
