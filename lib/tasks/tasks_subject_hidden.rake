namespace :tasks do
  task subject_hidden: :environment do
    batch_size = 10_000
    0.step(Task.count, batch_size).each do |offset|
      Task.where(subject_hidden: nil).order(:id).offset(offset).limit(batch_size).update_all(subject_hidden: false)
    end
  end
end
