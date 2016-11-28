class Api::V2::Contacts::People::WebsitesController < Api::V2Controller
  def index
    authorize load_person, :show?
    load_websites
    render json: @websites
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
    @website.destroy
    render_200
  end

  private

  def load_websites
    @websites ||= website_scope.where(filter_params).to_a
  end

  def load_website
    @website ||= website_scope.find(params[:id])
  end

  def authorize_website
    authorize @website
  end

  def render_website
    render json: @website
  end

  def persist_website
    build_website
    authorize_website
    return show if save_website
    render_400_with_errors(@website)
  end

  def build_website
    @website ||= website_scope.build
    @website.assign_attributes(website_params)
    authorize @website
  end

  def save_website
    @website.save
  end

  def website_params
    params.require(:data).require(:attributes).permit(Person::Website::PERMITTED_ATTRIBUTES)
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

  def permited_filters
    []
  end

  def pundit_user
    action_name == 'index' ? PunditContext.new(current_user, load_contact) : current_user
  end
end
