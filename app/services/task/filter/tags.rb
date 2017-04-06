class Task::Filter::Tags < Task::Filter::Base
  def execute_query(tasks, filters)
    tasks.tagged_with(parse_list(filters[:tags]), any: filters[:any_tags].to_s == 'true')
  end
end
