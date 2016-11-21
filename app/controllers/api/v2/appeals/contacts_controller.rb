class Api::V2::Appeals::ContactsController < Api::V2::AppealsController
  def index
    load_contacts
    render json: @contacts
  end

  def show
    load_contact
    authorize_contact
    render_contact
  end

  def destroy
    load_contact
    authorize_contact
    @contact.destroy
    render_200
  end

  private

  def load_contacts
    @contacts ||= contacts.to_a
  end

  def load_contact
    @contact ||= Contact.find(params[:id])
  end

  def render_contact
    render json: @contact
  end

  def authorize_contact
    authorize @contact
  end

  def contacts
    params[:excluded] ? contact_scope.excluded_contacts : contact_scope.contacts
  end

  def contact_scope
    load_appeals.find(params[:appeal_id])
  end

  def load_appeals
    @appeal ||= current_user.account_lists.find(filter_params[:account_list_id]).appeals
  end
end
