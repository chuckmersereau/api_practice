class Api::V2::AccountLists::PrayerLettersAccountsController < Api::V2Controller
  def show
    load_prayer_letters_account
    authorize_prayer_letters_account
    render_prayer_letters_account
  end

  def create
    persist_prayer_letters_account
  end

  def destroy
    load_prayer_letters_account
    authorize_prayer_letters_account
    destroy_prayer_letters_account
  end

  def sync
    load_prayer_letters_account
    authorize_prayer_letters_account
    @prayer_letters_account.queue_subscribe_contacts
    render_200
  end

  private

  def destroy_prayer_letters_account
    @prayer_letters_account.destroy
    head :no_content
  end

  def load_prayer_letters_account
    @prayer_letters_account ||= prayer_letters_acount_scope.prayer_letters_account
    raise ActiveRecord::RecordNotFound unless @prayer_letters_account
  end

  def render_prayer_letters_account
    render json: @prayer_letters_account,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_prayer_letters_account
    build_prayer_letters_account
    authorize_prayer_letters_account

    if save_prayer_letters_account
      render_prayer_letters_account
    else
      render_with_resource_errors(@prayer_letters_account)
    end
  end

  def build_prayer_letters_account
    @prayer_letters_account ||= prayer_letters_acount_scope.prayer_letters_account&.build || PrayerLettersAccount.new
    @prayer_letters_account.assign_attributes(prayer_letters_account_params.merge(account_list_id: load_account_list.id))
    authorize_prayer_letters_account
  end

  def save_prayer_letters_account
    @prayer_letters_account.save(context: persistence_context)
  end

  def prayer_letters_account_params
    params
      .require(:prayer_letters_account)
      .permit(PrayerLettersAccount::PERMITTED_ATTRIBUTES)
  end

  def authorize_prayer_letters_account
    authorize @prayer_letters_account
  end

  def prayer_letters_acount_scope
    load_account_list
  end

  def load_account_list
    @account_list ||= AccountList.find_by!(uuid: params[:account_list_id])
  end

  def permitted_filters
    []
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
