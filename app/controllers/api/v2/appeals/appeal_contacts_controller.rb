class Api::V2::Appeals::AppealContactsController < Api::V2Controller
  before_action :load_appeal

  def index
    authorize @appeal, :show?
    load_appeal_contacts
    render json: @appeal_contacts.preload_valid_associations(include_associations),
           meta: meta_hash(@appeal_contacts),
           include: include_params,
           fields: field_params
  end

  def create
    persist_appeal_contact
  end

  def show
    load_appeal_contact
    authorize_appeal_contact
    render_appeal_contact
  end

  def destroy
    load_appeal_contact
    authorize_appeal_contact
    @appeal_contact.destroy
    head :no_content
  end

  private

  def load_appeal_contacts
    @appeal_contacts = AppealContact::Filterer.new(filter_params.merge(appeal_id: @appeal.id))
                                              .filter(scope: appeal_contact_scope, account_lists: account_lists)
                                              .reorder(sorting_param)
                                              .page(page_number_param)
                                              .per(per_page_param)
  end

  def load_appeal_contact
    @appeal_contact ||= appeal_contact_scope.find_by_uuid_or_raise!(params[:id])
  end

  def persist_appeal_contact
    build_appeal_contact
    authorize_appeal_contact

    if save_appeal_contact && @appeal_contact.destroy_related_excluded_appeal_contact
      render_appeal_contact
    else
      render_with_resource_errors(@appeal_contact)
    end
  end

  def build_appeal_contact
    @appeal_contact ||= appeal_contact_scope.build
    @appeal_contact.assign_attributes(appeal_contact_params)
  end

  def save_appeal_contact
    @appeal_contact.save(context: persistence_context)
  end

  def appeal_contact_params
    params
      .require(:appeal_contact)
      .permit(AppealContact::PERMITTED_ATTRIBUTES)
  end

  def appeal_contact_scope
    @appeal.appeal_contacts
  end

  def render_appeal_contact
    render json: @appeal_contact,
           status: :ok,
           include: include_params,
           fields: field_params
  end

  def authorize_appeal_contact
    authorize @appeal_contact
  end

  def load_appeal
    @appeal ||= Appeal.find_by_uuid_or_raise!(params[:appeal_id])
  end

  def pundit_user
    PunditContext.new(current_user)
  end

  def permitted_filters
    [:pledged_to_appeal]
  end
end
