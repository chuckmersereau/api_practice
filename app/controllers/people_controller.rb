class PeopleController < ApplicationController
  before_action :find_contact
  before_action :find_person, only: [:show, :edit, :update, :social_search]

  def show
    @person = current_account_list.people.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def new
    @person = Person.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def edit
  end

  def create
    @contact = current_account_list.contacts.find(params[:contact_id])
    Person.transaction do
      @person = @contact.people.new(person_params)

      respond_to do |format|
        if @person.save
          format.html { redirect_to @contact }
        else
          format.html { render action: 'new' }
        end
      end
    end
  end

  def update
    respond_to do |format|
      if @person.update_attributes(person_params)
        format.html { redirect_to @person }
      else
        format.html { render action: 'edit' }
      end
      format.json { respond_with_bip(@person) }
    end
  end

  def destroy
    @person = current_account_list.people.find(params[:id])
    @person.destroy

    respond_to do |format|
      format.html { redirect_to people_path }
    end
  end

  def merge
    ids_to_merge = params[:merge_people_ids].split(',')
    return unless ids_to_merge.length > 1 && ids_to_merge.include?(params[:merge_winner])

    people_to_merge = @contact.people.where(id: ids_to_merge - [params[:merge_winner]])
    merge_winner = @contact.people.find(params[:merge_winner])
    people_to_merge.each do |p|
      merge_winner.merge(p)
    end
  end

  def merge_sets
    merged_people_count = 0

    params[:merge_sets].each do |ids|
      merge_set_ids = ids.split(',')
      people = current_account_list.people.where(id: merge_set_ids)
      next if people.length <= 1
      merged_people_count += people.length

      winner_id = if params[:dup_person_winner].present?
                    params[:dup_person_winner][ids]
                  else
                    people.find { |person| person.id.to_s == merge_set_ids[0] }
                  end
      winner = people.find(winner_id)
      Person.transaction do
        (people - [winner]).each do |loser|
          winner.merge(loser)
        end
      end
    end if params[:merge_sets].present?
    redirect_to :back, notice: _('You just merged %{count} people').localize % { count: merged_people_count }
  end

  def not_duplicates
    ids = params[:ids].split(',')
    people = current_account_list.people.where(id: ids)

    people.each do |person|
      not_duplicated_with = (person.not_duplicated_with.to_s.split(',') + params[:ids].split(',') -
          [person.id.to_s]).uniq.join(',')
      person.update(not_duplicated_with: not_duplicated_with)
    end

    # Increment counters for the nicknames to track which nicknames are useful. We assume the first id is the nickname,
    # which is how the find duplicates page does it.
    first_person = people.find { |person| person.id == ids[0].to_i }
    other_people = people.select { |person| person.id != first_person.id }
    other_people.each do |other_person|
      Nickname.increment_not_duplicates(other_person.first_name, first_person.first_name)
    end

    respond_to do |wants|
      wants.html { redirect_to :back }
      wants.js { render nothing: true }
    end
  end

  private

  def find_person
    @person = current_account_list.people.find(params[:id])
  end

  def find_contact
    @contact = current_account_list.contacts.find(params[:contact_id]) if params[:contact_id]
  end

  def person_params
    params.require(:person).permit(Person::PERMITTED_ATTRIBUTES)
  end
end
