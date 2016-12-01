class Api::V2::Contacts::People::NetworksController < Api::V2Controller
  NETWORKS = { facebook: 'FacebookAccount',
               linkedin: 'LinkedinAccount',
               twitter: 'TwitterAccount',
               website: 'Website' }.freeze

  def index
    authorize load_person, :show?
    load_networks
    # render json: @networks, serializer: Person::NetworkSerializer
    render json: ActiveModel::SerializableResource.new(@networks, each_serializer: Person::NetworkSerializer).as_json,
           meta: meta_hash(@networks)
    # render json: @main_network, include: 'facebook_accounts, linkedin_accounts, twitter_accounts, websites'
           #meta: meta_hash(@main_network)
  end

  def show
    load_network
    authorize_network
    render_network
  end

  def create
    persist_network
  end

  def update
    load_network
    authorize_network
    persist_network
  end

  def destroy
    load_network
    authorize_network
    @network.destroy
    render_200
  end

  private

  def load_networks
    # @main_network ||= Person::Network.new(person_id: load_person.id)
    @networks ||= load_contact.people.joins(:facebook_accounts, :linkedin_accounts, :twitter_accounts, :websites)
                              .where(filter_params.merge({ people: { id: params[:person_id] } }))
                              .reorder(sorting_param)
                              .page(page_number_param)
                              .per(per_page_param)
    binding.pry
  end

  def load_network
    @network ||= network_scope.find(params[:id])
  end

  def render_network
    render json: @network
  end

  def persist_network
    build_network
    authorize_network
    return show if save_network
    render_400_with_errors(@network)
  end

  def build_network
    @network ||= network_scope.build
    @network.assign_attributes(network_params)
  end

  def authorize_network
    authorize @network
  end

  def save_network
    @network.save
  end

  def network_params
    params.require(:data).require(:attributes).permit(network_attributes)
  end

  def network_attributes
    "Person::#{network_name(filter_params[:network])}".constantize::PERMITTED_ATTRIBUTES
  end

  def network_scope
    load_networks_from_name(network_name(filter_params[:network]))
  end

  def load_networks_from_name(network)
    load_person.send(network.underscore.pluralize)
  end

  def network_name(name)
    NETWORKS[name.to_sym]
  end

  def load_person
    @person ||= load_contact.people.find(params[:person_id])
  end

  def load_contact
    @contact ||= Contact.find(params[:contact_id])
  end

  def permitted_filters
    [:network]
  end

  def pundit_user
    action_name == 'index' ? PunditContext.new(current_user, contact: load_contact) : current_user
  end
end
