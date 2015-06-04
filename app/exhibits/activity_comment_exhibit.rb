class ActivityCommentExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'ActivityComment'
  end

  def body
    return if self[:body].nil?
    EmailReplyParser.parse_reply(self[:body])
  end
end
