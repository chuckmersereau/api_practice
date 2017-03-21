class Api::V2::Contacts::TagsController < Api::V2Controller
  def index
    authorize_index
    load_tags
    render json: @tags,
           status: success_status,
           include: include_params,
           fields: field_params
  end

  def create
    load_contact
    authorize_contact
    persist_resource(contact_params[:name]) do |tag_name|
      @contact.tag_list.add(tag_name)
    end
  end

  def destroy
    load_contact
    authorize_contact
    destroy_tag
  end

  private

  def load_tags
    @tags ||= account_lists.map(&:contact_tags).flatten.uniq.sort_by(&:name)
  end

  def authorize_index
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end

  def destroy_tag
    persist_resource(params[:tag_name]) do |tag_name|
      @contact.tag_list.remove(tag_name)
    end

    head :no_content
  end

  def persist_resource(tag_name)
    tag_error = TagValidator.new.validate(tag_name)

    if tag_error
      render_with_resource_errors(tag_error)
    else
      yield(tag_name)
      @contact.save(context: persistence_context)
      render json: @contact,
             status: success_status,
             include: include_params,
             fields: field_params
    end
  end

  def load_contact
    @contact ||= Contact.find_by_uuid_or_raise!(params[:contact_id])
  end

  def authorize_contact
    authorize @contact
  end

  def contact_params
    params.require(:tag).permit(:name)
  end

  def permitted_filters
    [:account_list_id]
  end

  def pundit_user
    PunditContext.new(current_user, contact: @contact)
  end
end
