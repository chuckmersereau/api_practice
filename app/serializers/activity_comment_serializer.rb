class ActivityCommentSerializer < ApplicationSerializer
  include DisplayCase::ExhibitsHelper

  type :comments

  attributes :body

  belongs_to :person

  def body
    activity_comment_exhibit = exhibit(object)
    activity_comment_exhibit.body
  end
end
