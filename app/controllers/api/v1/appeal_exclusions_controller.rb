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
    current_account_list.appeals.find(params[:appeal_id])
  end
end
