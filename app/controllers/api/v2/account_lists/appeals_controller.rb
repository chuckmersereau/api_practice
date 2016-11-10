class Api::V2::AccountLists::AppealsController < Api::V2::AccountListsController
	def resource_scope
		current_account_list.appeals
	end

  def resource_attributes
    Appeal::PERMITTED_ATTRIBUTES
  end
end
