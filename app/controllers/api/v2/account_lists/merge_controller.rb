class Api::V2::AccountLists::MergeController < Api::V2Controller
  def create
    load_merge_account_list
    authorize_merge_account_list

    if @merge_account_list != load_account_list
      load_account_list.merge(@merge_account_list)
      head :created
    else
      render_400
    end
  end

  private

  def load_merge_account_list
    @merge_account_list ||= merge_account_list_scope.find(merge_account_list_params[:id])
  end

  def authorize_merge_account_list
    authorize @merge_account_list
  end

  def merge_account_list_params
    params.require(:data).require(:attributes).permit(:id)
  end

  def merge_account_list_scope
    current_user.account_lists
  end

  def load_account_list
    @account_list ||= AccountList.find(params[:account_list_id])
  end

  def permitted_filters
    []
  end

  def pundit_user
    PunditContext.new(current_user, account_list: load_account_list)
  end
end
