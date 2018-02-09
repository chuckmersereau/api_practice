class Api::V2::Contacts::People::MergesController < Api::V2Controller
  resource_type :merges

  def create
    load_records
    authorize_merge
    merge_people
    render_winner
  end

  private

  def merge_params
    params
      .require(:merge)
      .permit(merge_attributes)
  end

  def merge_attributes
    [:winner_id, :loser_id]
  end

  def authorize_merge
    authorize(@winner, :update?)
    authorize(@loser, :destroy?)
  end

  def load_records
    load_contact
    load_people
  end

  def load_contact
    @current_contact = Contact.find_by!(id: params[:contact_id])
  end

  def load_people
    @winner = Person.find(merge_params[:winner_id])
    @loser  = Person.find(merge_params[:loser_id])
  end

  def merge_people
    @winner.merge(@loser)
  end

  def render_winner
    render json: @winner,
           include: include_params,
           fields: field_params
  end

  def field_params
    fields = super[:merges]

    return {} unless fields

    {
      people: fields
    }
  end

  def pundit_user
    PunditContext.new(current_user, contact: @current_contact)
  end
end
