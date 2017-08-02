class Api::V2::Contacts::DuplicatesController < Api::V2Controller
  resource_type :contacts

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

    @dup_contacts = Kaminari.paginate_array(duplicates_without_doubles)
                            .page(page_number_param)
                            .per(per_page_param)
  end

  def duplicates_without_doubles
    @dup_contacts.each_with_object([]) do |duplicate, dups_to_keep|
      if dups_to_keep.none? { |dup_to_keep| dup_to_keep.shares_an_id_with?(duplicate) }
        dups_to_keep << duplicate
      end
    end
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
           include: include_params,
           fields: field_params
  end

  def permitted_filters
    [:account_list_id]
  end

  def pundit_user
    PunditContext.new(current_user)
  end
end
