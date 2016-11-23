class TaskSerializer < ApplicationSerializer
  attributes :account_list_id,
             :activity_type,
             :completed,
             :completed_at,
             :next_action,
             :no_date,
             :result,
             :starred,
             :subject,
             :tag_list

  attribute :activity_comments_count, key: :comments_count
  attribute :contact_ids, key: :contacts
  attribute :start_at, key: :due_date

  has_many :activity_comments, key: :comments, root: :comments
  has_many :people
end
