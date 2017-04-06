class Task::Filter::Tags < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.tagged_with(filters[:tags].split(',').map(&:strip), any: filters[:any_tags].to_s == 'true')
  end
end
