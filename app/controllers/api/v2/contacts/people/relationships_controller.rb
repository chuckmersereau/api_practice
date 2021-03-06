class Api::V2::Contacts::People::RelationshipsController < Api::V2Controller
  before_action :load_relationship, :authorize_relationship, only: [:show, :update, :destroy]

  resource_type :family_relationships

  def index
    load_relationships
    authorize @person, :show?
    render json: @relationships.preload_valid_associations(include_associations),
           meta: meta_hash(@relationships),
           include: include_params,
           fields: field_params
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
    destroy_relationship
  end

  private

  def destroy_relationship
    @relationship.destroy
    head :no_content
  end

  def persist_relationship
    build_relationship
    authorize_relationship
    return show if save_relationship

    render_with_resource_errors(@relationship)
  end

  def load_relationships
    @relationships = relationship_scope.where(filter_params)
                                       .reorder(sorting_param)
                                       .page(page_number_param)
                                       .per(per_page_param)
  end

  def load_relationship
    @relationship ||= relationship_scope.find(params[:id])
  end

  def authorize_relationship
    authorize @relationship
  end

  def render_relationship
    render json: @relationship,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def build_relationship
    @relationship ||= relationship_scope.build
    @relationship.assign_attributes(relationship_params)
  end

  def save_relationship
    @relationship.save(context: persistence_context)
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
    params.require(:family_relationship)
          .permit(relationship_attributes)
  end

  def relationship_attributes
    FamilyRelationship::PERMITTED_ATTRIBUTES
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end
end
