class Api::V2::Contacts::People::WebsitesController < Api::V2Controller
  def index
    authorize load_person, :show?
    load_websites
    render json: @websites.preload_valid_associations(include_associations),
           meta: meta_hash(@websites),
           include: include_params,
           fields: field_params
  end

  def show
    load_website
    authorize_website
    render_website
  end

  def create
    persist_website
  end

  def update
    load_website
    authorize_website
    persist_website
  end

  def destroy
    load_website
    authorize_website
    destroy_website
  end

  private

  def destroy_website
    @website.destroy
    head :no_content
  end

  def load_websites
    @websites = website_scope.where(filter_params)
                             .reorder(sorting_param)
                             .page(page_number_param)
                             .per(per_page_param)
  end

  def load_website
    @website ||= website_scope.find(params[:id])
  end

  def authorize_website
    authorize @website
  end

  def render_website
    render json: @website,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def persist_website
    build_website
    authorize_website

    if save_website
      render_website
    else
      render_with_resource_errors(@website)
    end
  end

  def build_website
    @website ||= website_scope.build
    @website.assign_attributes(website_params)
  end

  def save_website
    @website.save(context: persistence_context)
  end

  def website_params
    params.require(:website)
          .permit(Person::Website::PERMITTED_ATTRIBUTES)
  end

  def website_scope
    load_person.websites
  end

  def load_person
    @person ||= load_contact.people.find(params[:person_id])
  end

  def load_contact
    @contact ||= Contact.find(params[:contact_id])
  end

  def pundit_user
    action_name == 'index' ? PunditContext.new(current_user, contact: load_contact) : current_user
  end
end
