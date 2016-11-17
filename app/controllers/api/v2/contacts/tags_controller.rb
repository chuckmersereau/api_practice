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
    persist_resource(params[:tag_name]) do |tag_name|
      @contact.tag_list.remove(tag_name)
    end
  end

  private

  def persist_resource(tag_name)
    tag_error = TagValidator.new.validate(tag_name)
    if tag_error
      render_400_with_errors(tag_error)
    else
      yield(tag_name)
      @contact.save
      render json: @contact
    end
  end

  def load_contact
    @contact ||= Contact.find(params[:contact_id])
  end

  def authorize_contact
    authorize @contact
  end

  def contact_params
    params.require(:data).require(:attributes).permit(:name)
  end
end
