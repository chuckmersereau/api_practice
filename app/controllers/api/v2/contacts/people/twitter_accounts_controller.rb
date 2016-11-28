class Api::V2::Contacts::People::TwitterAccountsController < Api::V2Controller
  def index
    authorize load_person, :show?
    load_tw_accounts
    render json: @tw_accounts
  end

  def show
    load_tw_account
    authorize_tw_account
    render_tw_account
  end

  def create
    persist_tw_account
  end

  def update
    load_tw_account
    authorize_tw_account
    persist_tw_account
  end

  def destroy
    load_tw_account
    authorize_tw_account
    @tw_account.destroy
    render_200
  end

  private

  def load_tw_accounts
    @tw_accounts ||= tw_account_scope.where(filter_params).to_a
  end

  def load_tw_account
    @tw_account ||= tw_account_scope.find(params[:id])
  end

  def authorize_tw_account
    authorize @tw_account
  end

  def render_tw_account
    render json: @tw_account
  end

  def persist_tw_account
    build_tw_account
    authorize_tw_account
    return show if save_tw_account
    render_400_with_errors(@tw_account)
  end

  def build_tw_account
    @tw_account ||= tw_account_scope.build
    @tw_account.assign_attributes(tw_account_params)
    authorize @tw_account
  end

  def save_tw_account
    @tw_account.save
  end

  def tw_account_params
    params.require(:data).require(:attributes).permit(Person::TwitterAccount::PERMITTED_ATTRIBUTES)
  end

  def tw_account_scope
    load_person.twitter_accounts
  end

  def load_person
    @person ||= load_contact.people.find(params[:person_id])
  end

  def load_contact
    @contact ||= Contact.find(params[:contact_id])
  end

  def permited_filters
    []
  end

  def pundit_user
    action_name == 'index' ? PunditContext.new(current_user, load_contact) : current_user
  end
end
