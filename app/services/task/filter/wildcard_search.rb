class Task::Filter::WildcardSearch < Task::Filter::Base
  def execute_query(tasks, filters)
    if filters[:wildcard_search] != 'null' && filters[:wildcard_search].present?
      @tasks = tasks
      @filters = filters
      tasks = tasks.where('activities.subject ilike ? OR activities.id IN (?)', wildcard_string, relevant_task_ids)
    end
    tasks
  end

  private

  def relevant_task_ids
    (tagged_task_ids + task_ids_with_relevant_contact_name + task_ids_with_relevant_comment).uniq
  end

  def tagged_task_ids
    @tasks.tagged_with(@filters[:wildcard_search].split(',').flatten, wild: true, any: true).reorder(:id).ids
  end

  def task_ids_with_relevant_contact_name
    @tasks.joins(:contacts).where('contacts.name ilike ?', wildcard_string).reorder(:id).ids
  end

  def task_ids_with_relevant_comment
    @tasks.joins(:comments).where('activity_comments.body ilike ?', wildcard_string).reorder(:id).ids
  end

  def wildcard_string
    "%#{@filters[:wildcard_search]}%"
  end

  def valid_filters?(filters)
    super && filters[:wildcard_search].is_a?(String)
  end
end
