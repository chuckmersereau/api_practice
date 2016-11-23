class ActivityCommentSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  attributes :activity_id,
             :body,
             :person_id

  def body
    activity_comment_exhibit = exhibit(object)
    activity_comment_exhibit.body
  end
end
