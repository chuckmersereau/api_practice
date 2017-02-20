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
    @dup_people = account_lists.flat_map do |account_list|
      Person::DuplicatesFinder.new(account_list).find
    end
    @dup_people = Kaminari.paginate_array(@dup_people)
                          .page(page_number_param)
                          .per(per_page_param)
  end

  def render_duplicates
    render json: @dup_people,
           meta: meta_hash(@dup_people),
           include: include_params
  end

  def current_contact
    @duplicate&.shared_contact
  end

  def pundit_user
    PunditContext.new(current_user, contact: current_contact)
  end
end
