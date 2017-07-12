class AsyncScheduler
  def self.schedule_over_24h(relation, method, queue)
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

  def self.schedule_worker_jobs_over_24h(worker_class, job_arguments_collection)
    number_of_jobs = job_arguments_collection.size
    return if number_of_jobs == 0

    interval_in_seconds = 24.hours / number_of_jobs
    start_time = Time.current

    job_arguments_collection.each_with_index do |job_arguments, index|
      perform_time = start_time + (index * interval_in_seconds).seconds
      worker_class.perform_at(perform_time, *job_arguments)
    end
  end
end
