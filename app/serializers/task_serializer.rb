class TaskSerializer < ApplicationSerializer
  attributes :account_list_id,
             :activity_type,
             :completed,
             :completed_at,
             :next_action,
             :no_date,
             :result,
             :starred,
             :start_at,
             :subject,
             :tag_list

  attribute :activity_comments_count, key: :comments_count
  attribute :start_at, key: :due_date

  has_many :activity_comments, key: :comments, root: :comments
  has_many :contacts
  has_many :people

  belongs_to :account_list

  def account_list_id
    object.account_list.uuid
  end
end
