class Api::V2::Tasks::Tags::BulkController < Api::V2Controller
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

  def destroy_tags
    @tags.destroy_all
    head :no_content
  end

  def load_tags
    @tags ||=
      ActsAsTaggableOn::Tagging.joins(:tag)
                               .where(taggable_type: 'Activity',
                                      taggable_id: taggable_ids,
                                      tags: { name: tag_name })
  end

  def permitted_filters
    [:account_list_id, :task_ids]
  end

  def tags_scope
    @tasks ||= Task.where(tasks_query).tap(&:first!)
  end

  def task_uuids
    filter_params[:task_ids].to_s.split(',').map(&:strip)
  end

  def tasks_query
    {
      account_list: account_lists
    }.tap do |query|
      query[:uuid] = task_uuids if task_uuids.present?
    end
  end
end
