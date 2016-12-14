class Api::V2::Contacts::TagsController < Api::V2Controller
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

  def destroy_tag
    persist_resource(params[:tag_name]) do |tag_name|
      @contact.tag_list.remove(tag_name)
    end

    head :no_content
  end

  def persist_resource(tag_name)
    tag_error = TagValidator.new.validate(tag_name)

    if tag_error
      render_400_with_errors(tag_error)
    else
      yield(tag_name)
      @contact.save
      render json: @contact,
             status: success_status
    end
  end

  def load_contact
    @contact ||= Contact.find_by!(uuid: params[:contact_id])
  end

  def authorize_contact
    authorize @contact
  end

  def contact_params
    params.require(:data).require(:attributes).permit(:name)
  end

  def pundit_user
    PunditContext.new(current_user, contact: @contact)
  end
end
