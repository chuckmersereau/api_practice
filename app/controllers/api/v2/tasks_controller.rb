class Api::V2::TasksController < Api::V2::ResourceController
  private

  def resource_class
    Task
  end

  def resource_scope
    current_account_list.tasks
  end

  def params_keys
  	%w(account_list_id)
  end
end
