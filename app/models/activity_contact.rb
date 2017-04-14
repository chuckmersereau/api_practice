class ActivityContact < ApplicationRecord
  belongs_to :activity
  belongs_to :task, foreign_key: 'activity_id'
  belongs_to :contact
  after_save :update_contact_uncompleted_tasks_count
  after_destroy :update_contact_uncompleted_tasks_count

  # attr_accessible :contact_id, :activity_id

  private

  def update_contact_uncompleted_tasks_count
    contact.try(:update_uncompleted_tasks_count)
  end
end
