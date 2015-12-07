class AsyncScheduler
  def self.schedule_over_24h(relation, method)
    count = relation.count
    return if count == 0
    interval = 24.hours / count
    relation.find_each.with_index do |object, index|
      relation.model.perform_in(interval * index, object.id, method)
    end
  end
end
