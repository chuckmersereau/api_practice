class AsyncScheduler
  def self.schedule_over_24h(relation, method, queue = :import)
    count = relation.count
    return if count == 0
    interval = 24.hours / count
    relation.find_each.with_index do |object, index|
      Sidekiq::Client.push(
        'class' => relation.model,
        'args' => [object.id, method],
        'at' => (Time.now + interval * index).to_f,
        'queue' => queue
      )
    end
  end
end
