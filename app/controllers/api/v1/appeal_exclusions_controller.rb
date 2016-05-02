class Api::V1::AppealExclusionsController < Api::V1::BaseController
  def index
    result = appeal.excluded_appeal_contacts
    render json: result, callback: params[:callback], each_serializer: ExcludedAppealContactSerializer
  end

  def destroy
    exclusion = appeal.excluded_appeal_contacts.find(params[:id])
    exclusion.delete
    render json: exclusion, callback: params[:callback]
  end

  private

  def appeal
    account_list = if params[:account_list_id]
                     current_user.account_lists.find(params[:account_list_id])
                   else
                     current_account_list
                   end
    account_list.appeals.find(params[:appeal_id])
  end
end
