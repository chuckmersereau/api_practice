class Api::V2::Contacts::People::NetworksController < Api::V2Controller

  NETWORKS = { facebook: 'FacebookAccount',
               linkedin: 'LinkedinAccount',
               twitter: 'TwitterAccount',
               website: 'Website' }.freeze

  def index
    authorize load_person, :show?
    load_networks
    render json: @networks.to_json
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

  def available_networks
    permited_networks = %w(facebook linkedin twitter website)
    filter_params[:networks].delete(' ').split(',').keep_if { |k, _| permited_networks.include? k }
  end

  def load_networks
    @networks = nil
    available_networks.map{ |network| 
      serializer_name = "Person::#{network_name(network)}Serializer".constantize
      results = load_scope(network_name(network)).where(filter_params.except(:networks)).to_a 
      response = ActiveModelSerializers::SerializableResource.new(results).as_json[:data]
      @networks = @networks ? @networks + response : response
    }
    @networks = { data: @networks }
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
    authorize @network
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
    load_scope(network_name(filter_params[:network]))
  end

  def load_scope(network)
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

  def permited_filters
    [:networks, :network]
  end

  def pundit_user
    action_name == 'index' ? PunditContext.new(current_user, contact: load_contact) : current_user
  end
end
