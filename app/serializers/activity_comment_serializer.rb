class ActivityCommentSerializer < ActiveModel::Serializer
  include DisplayCase::ExhibitsHelper

  embed :ids, include: true
  attributes :id, :body, :activity_id, :person_id, :created_at, :updated_at

  def body
    activity_comment_exhibit = exhibit(object)
    activity_comment_exhibit.body
  end
end
