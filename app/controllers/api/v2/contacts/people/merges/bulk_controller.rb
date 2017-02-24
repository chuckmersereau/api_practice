class Api::V2::Contacts::People::Merges::BulkController < Api::V2Controller
  skip_before_action :validate_and_transform_json_api_params

  PersonMerge = Struct.new(:winner, :loser)

  def create
    skip_authorization
    load_people
    build_merge_structs
    process_and_render_merges do |merge|
      merge_people(merge)
      merge.winner
    end
  end

  private

  def person_uuids
    params[:data].flat_map do |merge_params|
      attributes = extract_merge_attributes(merge_params)
      [attributes[:winner_id], attributes[:loser_id]]
    end
  end

  def extract_merge_attributes(params)
    params
      .require(:data)
      .require(:attributes)
      .permit(merge_attributes)
  end

  def merge_attributes
    [:winner_id, :loser_id]
  end

  def load_people
    @people = people_scope.where(uuid: person_uuids).tap(&:first!).to_a
  end

  def people_scope
    Person.joins(:account_lists).where(account_lists: { id: account_lists })
  end

  def build_merge_structs
    @merges = params[:data].map do |merge_params|
      attributes = extract_merge_attributes(merge_params)

      build_merge_from_attributes(attributes)
    end
    @merges.compact!
    raise ActiveRecord::RecordNotFound unless @merges.any?
  end

  def build_merge_from_attributes(attributes)
    winner = @people.find { |person| person.uuid == attributes[:winner_id] }
    loser  = @people.find { |person| person.uuid == attributes[:loser_id] }

    return nil unless (winner && loser) && (winner.contact_ids & loser.contact_ids).any?

    PersonMerge.new(winner, loser)
  end

  def process_and_render_merges(&process)
    winners = @merges.map(&process)
    render json: BulkResourceSerializer.new(resources: winners)
  end

  def merge_people(merge)
    merge.winner.merge(merge.loser)
  end

  def permitted_filters
    []
  end

  def pundit_user
    PunditContext.new(current_user)
  end
end
