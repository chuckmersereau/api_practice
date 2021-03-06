class ActivitySerializer < ApplicationSerializer
  attributes :activity_type,
             :completed,
             :completed_at,
             :location,
             :next_action,
             :notification_time_before,
             :notification_time_unit,
             :notification_type,
             :result,
             :starred,
             :start_at,
             :subject,
             :subject_hidden,
             :tag_list

  attribute :activity_comments_count, key: :comments_count

  has_many :comments
  has_many :contacts
  has_many :people
  has_many :email_addresses
  has_many :phone_numbers
  has_many :activity_contacts

  belongs_to :account_list

  def tag_list
    object.tags.collect(&:name)
  end

  def subject_hidden
    !!object.subject_hidden
  end
end
