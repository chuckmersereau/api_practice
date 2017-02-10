module Types
  TaskConnectionWithAnalyticsType = TaskType.define_connection do
    name 'TaskConnectionWithAnalytics'

    field :analytics, !TaskAnalyticsType, 'Analytics on this set of Tasks' do
      resolve -> (obj, args, ctx) {
        Task::Analytics.new(obj.nodes)
      }
    end
  end
end
