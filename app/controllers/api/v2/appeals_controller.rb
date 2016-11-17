class Api::V2::AppealsController < Api::V2::ResourceController
  include ParamsFilters

  private

  def resource_class
    Appeal
  end

  def resource_scope
    current_account_list.appeals
  end
end
