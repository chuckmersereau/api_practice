class Api::V2::AppealsController < Api::V2::ResourceController
  private

  def resource_class
    Appeal
  end

  def resource_scope
    current_account_list.appeals
  end

  def params_keys
  	%w(account_list_id)
  end
end
