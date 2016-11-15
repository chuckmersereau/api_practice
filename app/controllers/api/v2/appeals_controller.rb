class Api::V2::AppealsController < Api::V2::ResourceController
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
    Appeal.that_belongs_to(params[:account_list_id])
  end

  def relevant_appeal_id
    params[:appeal_id] ? params[:appeal_id] : params[:id]
  end
end
