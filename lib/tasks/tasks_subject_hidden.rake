namespace :tasks do
  task subject_hidden: :environment do
    Task.find_each do |task|
      task.update_column(:subject_hidden, false)
    end
  end
end
