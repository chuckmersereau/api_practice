class Api::V2::AccountLists::MergeController < Api::V2Controller
  def create
    load_merge_account_list
    authorize_merge_account_list

    if @merge_account_list != load_account_list
      load_account_list.merge(@merge_account_list)

      render json: load_account_list,
             status: :created
    else
      render_400(detail: create_error_message)
    end
  end

  private

  def load_merge_account_list
    @merge_account_list ||= merge_account_list_scope.find_by!(id: merge_account_list_params[:account_list_to_merge_id])
  end

  def authorize_merge_account_list
    authorize @merge_account_list
  end

  def merge_account_list_params
    params
      .require(:merge)
      .permit(:account_list_to_merge_id)
  end

  def merge_account_list_scope
    current_user.account_lists
  end

  def load_account_list
    @account_list ||= AccountList.find_by_uuid_or_raise!(params[:account_list_id])
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end

  def create_error_message
    "Account List to be merged can't be the same as the Account List being merged into"
  end
end
