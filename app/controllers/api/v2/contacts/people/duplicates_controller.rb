class Api::V2::Contacts::People::DuplicatesController < Api::V2Controller
  resource_type :people

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
    authorize(@duplicate.shared_contact, :update?)
    @duplicate.people.each { |person| authorize(person, :update?) }
  end

  def invalidate_duplicate
    @duplicate.invalidate!
  end

  def load_duplicate
    @duplicate = Person::Duplicate.find(params[:id])
  end

  def load_duplicates
    @duplicates = account_lists.flat_map do |account_list|
      Person::DuplicatesFinder.new(account_list).find
    end
    @duplicates = Kaminari.paginate_array(duplicates_without_doubles)
                          .page(page_number_param)
                          .per(per_page_param)
  end

  def duplicates_without_doubles
    @duplicates.each_with_object([]) do |duplicate, dups_to_keep|
      if dups_to_keep.none? { |dup_to_keep| dup_to_keep.shares_an_id_with?(duplicate) }
        dups_to_keep << duplicate
      end
    end
  end

  def render_duplicates
    render json: @duplicates,
           meta: meta_hash(@duplicates),
           include: include_params,
           fields: field_params
  end

  def current_contact
    @duplicate&.shared_contact
  end

  def permitted_filters
    [:account_list_id]
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end
end
