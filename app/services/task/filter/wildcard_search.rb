class Task::Filter::WildcardSearch < Task::Filter::Base
  def execute_query(tasks, filters)
    if filters[:wildcard_search] != 'null' && filters[:wildcard_search].present?
      @tasks = tasks
      @filters = filters
      tasks = tasks.where('activities.subject ilike ? OR activities.id IN (?)', "%#{filters[:wildcard_search]}%", tagged_tasks_ids)
    end
    tasks
  end

  def tagged_tasks_ids
    @tasks.tagged_with(@filters[:wildcard_search].split(',').flatten, any: @filters[:wildcard_search] == 'true').ids
  end
end
