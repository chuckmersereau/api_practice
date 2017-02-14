class ActivitySerializer < ApplicationSerializer
  attributes :activity_type,
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

  has_many :comments
  has_many :contacts

  belongs_to :account_list
end
