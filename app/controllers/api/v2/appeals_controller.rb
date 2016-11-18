class Api::V2::AppealsController < Api::V2::ResourceController
  private

  def resource_class
    Appeal
  end

  def resource_scope
    Appeal.where(filter_params)
  end

  def permited_params
    %w(account_list_id)
  end
end
