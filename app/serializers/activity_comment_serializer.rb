class ActivityCommentSerializer < ApplicationSerializer
  include DisplayCase::ExhibitsHelper

  attributes :body, :person_id, :person_name

  belongs_to :activity
  belongs_to :person

  def body
    activity_comment_exhibit = exhibit(object)
    activity_comment_exhibit.body
  end

  def person_id
    object.person.uuid
  end

  def person_name
    object.person.to_s
  end
end
