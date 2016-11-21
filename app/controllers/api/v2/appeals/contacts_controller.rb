class Api::V2::Appeals::ContactsController < Api::V2::AppealsController
  def index
    authorize @appeal :show?
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
    @contacts ||= contact_scope.to_a
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

  def contact_scope
    params[:excluded] ? load_appeal.excluded_contacts : load_appeal.contacts
  end

  def load_appeal
    current_user.account_lists.find(filter_params[:account_list_id]).appeals.find(params[:appeal_id])
  end
end
