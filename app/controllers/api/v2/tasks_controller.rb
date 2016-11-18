class Api::V2::TasksController < Api::V2::ResourceController
  private

  def resource_class
    Task
  end

  def resource_scope
    task_scope
  end

  def task_scope
    Task.that_belong_to(filter_params)
  end

  def permited_filters
  	%w(account_list_id)
  end
end
