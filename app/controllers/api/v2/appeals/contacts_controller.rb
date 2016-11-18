class Api::V2::Appeals::ContactsController < Api::V2::AppealsController
  def index
    load_contacts
    render json: @resources
  end

  def show
    load_contact
    authorize_contact
    render_appeal
  end

  def destroy
    load_contact
    authorize_contact
    @resource.destroy
    render_200
  end

  private

  def load_contacts
    @resources ||= contacts.to_a
  end

  def load_contact
    @resource ||= contacts.find(params[:id])
  end

  def authorize_contact
    authorize @resource
  end

  def contacts
    params[:excluded] ? contact_scope.excluded_contacts : contact_scope.contacts
  end

  def contact_scope
    appeal_scope.find_by(filter_params)
  end

  def permited_filters
    [:account_list_id]
  end
end
