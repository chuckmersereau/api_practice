class Api::V2::AccountLists::AppealsController < Api::V2::AccountListsController
	def resource_scope
		appeal_scope
	end

  def resource_attributes
    Appeal::PERMITTED_ATTRIBUTES
  end

  def current_appeal
    @current_appeal ||= appeal_scope.find(relevant_appeal_id)
  end

  private

  def appeal_scope
  	current_account_list.appeals
  end

  def relevant_appeal_id
    params[:appeal_id] ? params[:appeal_id] : params[:id]
  end
end
