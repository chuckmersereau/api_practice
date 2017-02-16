class Task::Filter::ExcludeTags < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.tagged_with(filters[:exclude_tags].split(',').flatten, exclude: true)
  end
end
