class Api::V2::Contacts::DuplicatesController < Api::V2Controller
  def index
    authorize_index
    load_duplicates
    render_duplicates
  end

  def destroy
    load_duplicate
    authorize_duplicate
    invalidate_duplicate
    head :no_content
  end

  private

  def authorize_index
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end

  def authorize_duplicate
    @duplicate.contacts.each { |contact| authorize(contact, :update?) }
  end

  def load_duplicates
    @dup_contacts = account_lists.flat_map do |account_list|
      Contact::DuplicatesFinder.new(account_list).find
    end

    @dup_contacts = Kaminari.paginate_array(@dup_contacts)
                            .page(page_number_param)
                            .per(per_page_param)
  end

  def load_duplicate
    @duplicate = Contact::Duplicate.find(params[:id])
  end

  def invalidate_duplicate
    @duplicate.invalidate!
  end

  def render_duplicates
    render json: @dup_contacts,
           meta: meta_hash(@dup_contacts),
           include: include_params
  end

  def pundit_user
    PunditContext.new(current_user)
  end
end
