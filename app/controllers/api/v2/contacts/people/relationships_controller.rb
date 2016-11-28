class Api::V2::Contacts::People::RelationshipsController < Api::V2Controller
  before_action :load_relationship, :authorize_relationship, only: [:show, :update, :destroy]

  def index
    load_relationships
    authorize @person, :show?
    render json: @relationships
  end

  def show
    render_relationship
  end

  def create
    persist_relationship
  end

  def update
    persist_relationship
  end

  def destroy
    @relationship.destroy
    render_200
  end

  private

  def persist_relationship
    build_relationship
    return show if save_relationship
    render_400_with_errors(@relationship)
  end

  def load_relationships
    @relationships ||= relationship_scope.to_a
  end

  def load_relationship
    @relationship ||= relationship_scope.find(params[:id])
  end

  def authorize_relationship
    authorize @relationship
  end

  def render_relationship
    render json: @relationship
  end

  def build_relationship
    @relationship ||= relationship_scope.build
    @relationship.assign_attributes(relationship_params)
    authorize @relationship
  end

  def save_relationship
    @relationship.save
  end

  def relationship_scope
    current_person.family_relationships
  end

  def current_contact
    @contact ||= Contact.find(params[:contact_id])
  end

  def current_person
    @person ||= current_contact.people.find(params[:person_id])
  end

  def relationship_params
    params.require(:data).require(:attributes).permit(relationship_attributes)
  end

  def relationship_attributes
    [:relationship, :person_id, :related_person_id]
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end
end
