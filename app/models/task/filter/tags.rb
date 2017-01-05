class Task::Filter::Tags < Task::Filter::Base
  def execute_query(tasks, filters)
    return unless valid_filters?(filters)
    tasks = tasks.tagged_with(filters[:tags].split(',').flatten, any: filters[:any_tags] == 'true') if filters[:tags].present?
    tasks = tasks.tagged_with(filters[:exclude_tags].split(',').flatten, exclude: true) if filters[:exclude_tags].present?
    tasks
  end

  private

  def valid_filters?(filters)
    super || filters[:exclude_tags].present?
  end
end
