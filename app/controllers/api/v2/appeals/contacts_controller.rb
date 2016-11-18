class Api::V2::Appeals::ContactsController < Api::V2::AppealsController
  private

  def resource_class
    Contact
  end

  def resource_scope
    params[:excluded] ? excluded_contacts : contacts
  end

  def contacts
    contact_scope.contacts
  end

  def excluded_contacts
    contact_scope.excluded_contacts
  end

  def contact_scope
    appeal_scope.find_by(filter_params)
  end

  def permited_filters
    %w(account_list_id)
  end
end
