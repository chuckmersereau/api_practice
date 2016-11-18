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
    binding.pry
    Appeal.find_by(filter_params)
  end

  def permited_params
    %w(appeal_id)
  end

  # def params_keys
  #   %w(account_list_id appeal_id)
  # end
end
