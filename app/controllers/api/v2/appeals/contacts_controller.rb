class Api::V2::Appeals::ContactsController < Api::V2Controller
  skip_before_action :validate_and_transform_json_api_params, only: [:create]

  def index
    authorize load_appeal, :show?
    load_contacts
    render json: @contacts, meta: meta_hash(@contacts), include: include_params, fields: field_params
  end

  def create
    authorize load_appeal, :update?
    authorize load_contact, :update?
    add_contact_to_appeal
    render_contact
  end

  def show
    load_appeal
    load_contact_from_appeal
    authorize_contact
    render_contact
  end

  def destroy
    authorize load_appeal, :update?
    authorize load_contact_from_appeal, :update?
    remove_contact
  end

  private

  def add_contact_to_appeal
    @appeal.contacts << @contact
  rescue ActiveRecord::RecordNotUnique
    # If the contact isn't unique, it is already a part of the appeal, and we
    # will return it anyway.
  end

  def remove_contact
    @appeal.contacts.destroy(@contact)
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
    @contact ||= Contact.find_by!(uuid: params[:id])
  end

  def load_contact_from_appeal
    @contact ||= @appeal.contacts.find_by!(uuid: params[:id])
  end

  def render_contact
    render json: @contact,
           status: :ok,
           include: include_params,
           fields: field_params
  end

  def authorize_contact
    authorize @contact
  end

  def load_appeal
    @appeal ||= Appeal.find_by!(uuid: params[:appeal_id])
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
