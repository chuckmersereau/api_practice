class Api::V2::TasksController < Api::V2::ResourceController
  private

  def resource_class
    Task
  end

  def resource_scope
    Task.where(filter_params)
  end

  def permited_params
  	%w(account_list_id)
  end
end
