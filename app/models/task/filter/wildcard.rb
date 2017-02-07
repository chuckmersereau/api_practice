class Task::Filter::Wildcard < Task::Filter::Base
  def execute_query(tasks, filters)
    if filters[:wildcard] != 'null' && filters[:wildcard].present?
      task_list = tasks.where('lower(subject) like :search', search: filters[:wildcard].downcase)
      task_list << tasks.tagged_with(filters[:wildcard].downcase, any: true)
    end
    task_list.flatten
  end
end
