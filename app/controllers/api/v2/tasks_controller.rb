class Api::V2::TasksController < Api::V2::ResourceController
  private

  def resource_class
    Task
  end

  def resource_scope
    Task.that_belong_to(current_user)
  end
end
