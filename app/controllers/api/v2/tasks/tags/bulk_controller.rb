class Api::V2::Tasks::Tags::BulkController < Api::V2::BulkController
  include BulkTaggable

  resource_type :tags

  def create
    load_tasks
    authorize_tasks
    add_tags_to_tasks
    render_tasks
  end

  def destroy
    load_tags
    authorize_tags
    destroy_tags
  end

  private

  def add_tags_to_tasks
    @tasks.each do |task|
      task.tag_list.add(*tag_names)
      task.save
    end
  end

  def authorize_tags
    account_lists.each { |account_list| authorize(account_list, :show?) }
  end

  def authorize_tasks
    @tasks.each { |task| authorize(task, :update?) }
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
                                      tags: { name: tag_names })
  end

  def load_tasks
    @tasks ||= tasks_scope
  end

  def permitted_filters
    [:account_list_id, :task_ids]
  end

  def render_tasks
    render json: BulkResourceSerializer.new(resources: @tasks)
  end

  def task_ids
    filter_params[:task_ids].to_s.split(',').map(&:strip)
  end

  def tasks_query
    {
      account_list: account_lists
    }.tap do |query|
      query[:id] = task_ids if task_ids.present?
    end
  end

  def tasks_scope
    Task.where(tasks_query).tap(&:first!)
  end
  alias tags_scope tasks_scope
end
