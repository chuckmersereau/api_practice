class Api::V2::Contacts::Merges::BulkController < Api::V2Controller
  skip_before_action :validate_and_transform_json_api_params
  before_action :reject_if_in_batch_request

  Merge = Struct.new(:winner, :loser)

  def create
    skip_authorization
    load_contacts
    build_merge_structs
    process_and_render_merges do |merge|
      merge_contacts(merge)
      merge.winner
    end
  end

  private

  def contact_uuids
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

  def load_contacts
    @contacts = contact_scope.where(uuid: contact_uuids).tap(&:first!).to_a
  end

  def contact_scope
    current_user.contacts
  end

  def build_merge_structs
    @merges = params[:data].map do |merge_params|
      attributes = extract_merge_attributes(merge_params)

      build_merge_from_attributes(attributes)
    end.compact

    raise ActiveRecord::RecordNotFound unless @merges.any?
  end

  def build_merge_from_attributes(attributes)
    winner = @contacts.find { |contact| contact.uuid == attributes[:winner_id] }
    loser  = @contacts.find { |contact| contact.uuid == attributes[:loser_id] }

    return nil unless (winner && loser) && (winner.account_list_id == loser.account_list_id)

    Merge.new(winner, loser)
  end

  def process_and_render_merges(&process)
    winners = @merges.map(&process)
    render json: BulkResourceSerializer.new(resources: winners)
  end

  def merge_contacts(merge)
    merge.winner.merge(merge.loser)
  end

  def pundit_user
    PunditContext.new(current_user)
  end
end
