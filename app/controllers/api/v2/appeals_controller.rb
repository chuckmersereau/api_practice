class Api::V2::AppealsController < Api::V2::ResourceController
  private

  def resource_class
    Appeal
  end

  def resource_scope
    appeal_scope
  end

  def appeal_scope
    Appeal.that_belong_to(filter_params)
  end

  def permited_filters
    %w(account_list_id)
  end
end
