class Api::V2::Appeals::ContactsController < Api::V2Controller
  def index
    authorize load_appeal, :show?
    load_contacts
    render json: @contacts, meta: meta_hash(@contacts)
  end

  def show
    load_contact
    authorize_contact
    render_contact
  end

  def destroy
    load_contact
    authorize_contact
    destroy_contact
  end

  private

  def destroy_contact
    @contact.destroy
    head :no_content
  end

  def load_contacts
    excluded = filter_params[:excluded].to_i
    @contacts = load_appeal.selected_contacts(excluded)
                           .where(filters_without_excluded)
                           .reorder(sorting_param)
                           .page(page_number_param)
                           .per(per_page_param)
  end

  def load_contact
    @contact ||= Contact.find(params[:id])
  end

  def render_contact
    render json: @contact,
           status: success_status
  end

  def authorize_contact
    authorize @contact
  end

  def load_appeal
    @appeal ||= Appeal.find(params[:appeal_id])
  end

  def filters_without_excluded
    filter_params.except(:excluded)
  end

  def permitted_filters
    [:excluded, :account_list_id]
  end

  def pundit_user
    PunditContext.new(current_user, contact: @contact)
  end
end
