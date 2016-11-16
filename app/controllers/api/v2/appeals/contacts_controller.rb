class Api::V2::Appeals::ContactsController < Api::V2::AppealsController
  def resource_scope
    params[:excluded] ? excluded_contacts : contacts
  end

  private

  def contacts
    current_appeal.contacts
  end

  def excluded_contacts
    current_appeal.excluded_contacts
  end
end
