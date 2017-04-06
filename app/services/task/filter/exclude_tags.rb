class Task::Filter::ExcludeTags < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.tagged_with(parse_list(filters[:exclude_tags]), exclude: true)
  end
end
