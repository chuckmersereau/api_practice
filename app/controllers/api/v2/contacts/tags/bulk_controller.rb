class Api::V2::Contacts::Tags::BulkController < Api::V2Controller
  include BulkTagDeleteable

  skip_before_action :validate_and_transform_json_api_params

  def destroy
    load_tags
    authorize_tags
    destroy_tags
  end

  private

  def authorize_tags
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end

  def contact_uuids
    filter_params[:contact_ids].to_s.split(',').map(&:strip)
  end

  def contacts_query
    {
      account_list: account_lists
    }.tap do |query|
      query[:uuid] = contact_uuids if contact_uuids.present?
    end
  end

  def destroy_tags
    @tags.destroy_all
    head :no_content
  end

  def load_tags
    @tags ||=
      ActsAsTaggableOn::Tagging.joins(:tag)
                               .where(taggable_type: 'Contact',
                                      taggable_id: taggable_ids,
                                      tags: { name: tag_name })
  end

  def tags_scope
    @contacts ||= Contact.where(contacts_query).tap(&:first!)
  end

  def permitted_filters
    [:account_list_id, :contact_ids]
  end
end
