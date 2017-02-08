class Api::V2::Contacts::MergesController < Api::V2Controller
  resource_type :merges

  def create
    load_contacts
    authorize_merge
    merge_contacts
    render_winner
  end

  private

  def field_params
    params = super[:merges]

    return {} unless params

    {
      contacts: params
    }
  end

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

  def load_contacts
    @winner = Contact.find(merge_params[:winner_id])
    @loser  = Contact.find(merge_params[:loser_id])
  end

  def merge_contacts
    @winner.merge(@loser)
  end

  def render_winner
    render json: @winner,
           include: include_params,
           fields: field_params
  end

  def pundit_user
    PunditContext.new(current_user)
  end
end
