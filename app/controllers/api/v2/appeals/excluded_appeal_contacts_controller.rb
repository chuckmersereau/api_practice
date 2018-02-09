class Api::V2::Appeals::ExcludedAppealContactsController < Api::V2Controller
  resource_type :excluded_appeal_contacts
  before_action :load_appeal

  def index
    authorize @appeal, :show?
    load_excluded_appeal_contacts
    render json: @excluded_appeal_contacts.preload_valid_associations(include_associations),
           meta: meta_hash(@excluded_appeal_contacts),
           include: include_params,
           fields: field_params
  end

  def show
    load_excluded_appeal_contact
    authorize_excluded_appeal_contact
    render_excluded_appeal_contact
  end

  def destroy
    load_excluded_appeal_contact
    authorize_excluded_appeal_contact
    @excluded_appeal_contact.destroy
    head :no_content
  end

  private

  def load_excluded_appeal_contacts
    @excluded_appeal_contacts = excluded_appeal_contact_scope.where(filter_params)
                                                             .joins(sorting_join)
                                                             .reorder(sorting_param)
                                                             .page(page_number_param)
                                                             .per(per_page_param)
  end

  def load_excluded_appeal_contact
    @excluded_appeal_contact ||= excluded_appeal_contact_scope.find_by!(id: params[:id])
  end

  def excluded_appeal_contact_scope
    Appeal::ExcludedAppealContact.where(appeal: @appeal)
  end

  def render_excluded_appeal_contact
    render json: @excluded_appeal_contact,
           status: :ok,
           include: include_params,
           fields: field_params
  end

  def authorize_excluded_appeal_contact
    authorize @excluded_appeal_contact
  end

  def load_appeal
    @appeal ||= Appeal.find_by!(id: params[:appeal_id])
  end

  def pundit_user
    PunditContext.new(current_user)
  end

  def permitted_sorting_params
    %w(contact.name)
  end
end
