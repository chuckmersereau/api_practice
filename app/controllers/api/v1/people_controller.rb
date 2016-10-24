class Api::V1::PeopleController < Api::V1::BaseController
  def index
    render json: people, callback: params[:callback]
  end

  def show
    person = people.find(params[:id])
    render json: person, callback: params[:callback]
  rescue
    render json: { errors: ['Not Found'] }, callback: params[:callback], status: :not_found
  end

  def merge
    contact = current_account_list.contacts.find(params[:contact_id])
    ids_to_merge = params[:people_ids]

    if contact && ids_to_merge.length > 1 && ids_to_merge.include?(params[:winner])
      people_to_merge = contact.people.where(id: ids_to_merge - [params[:winner]])
      merge_winner = contact.people.find(params[:winner])
      people_to_merge.each do |p|
        merge_winner.merge(p)
      end
      render json: { success: true }
    else
      render json: { status: false }
    end
  end

  def merge
    contact = current_account_list.contacts.find(params[:contact_id])
    ids_to_merge = params[:people_ids]

    if contact && ids_to_merge.length > 1 && ids_to_merge.include?(params[:winner])
      people_to_merge = contact.people.where(id: ids_to_merge - [params[:winner]])
      merge_winner = contact.people.find(params[:winner])
      people_to_merge.each do |p|
        merge_winner.merge(p)
      end
      render json: { success: true }
    else
      render json: { status: false }
    end
  end

  protected

  def people
    # We want all the people associated with contacts, and also other users of this account list
    Person.where(id: current_account_list.people.pluck('people.id') + current_account_list.users.pluck('people.id'))
          .includes(:phone_numbers, :email_addresses)
  end
end
