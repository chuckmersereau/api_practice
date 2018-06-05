class ActivityContact < ApplicationRecord
  audited associated_with: :activity, on: [:destroy]

  attr_accessor :skip_contact_task_counter_update
  belongs_to :activity
  belongs_to :task, foreign_key: 'activity_id'
  belongs_to :contact
  after_save :update_contact_uncompleted_tasks_count, unless: :skip_contact_task_counter_update
  after_destroy :update_contact_uncompleted_tasks_count, unless: :skip_contact_task_counter_update

  private

  def update_contact_uncompleted_tasks_count
    contact.try(:update_uncompleted_tasks_count)
  end
end
