require 'spec_helper'

describe ActivityCommentExhibit do
  subject { ActivityCommentExhibit.new(activity_comment, context) }
  let(:person) { create(:person) }
  let(:activity_comment) { build(:activity_comment, person: person) }
  let(:context) { double }

  context '#body' do
    it 'returns a message with reply stripped' do
      activity_comment.body = "message body\n"\
        "On Thu, Jun 4, 2015 at 4:02 PM, tester <tester@gmail.com> wrote:\n"\
        '> This is long thread test with return message.'
      expect(subject.body).to eq('message body')
    end

    it 'returns an original message' do
      activity_comment.body = 'message body'
      expect(subject.body).to eq('message body')
    end

    it 'returns nil if the comment body is nil' do
      activity_comment.body = nil
      subject.body.should.nil?
    end

    it 'parse a message with unicode characters' do
      activity_comment.body = "message body\n"\
        "On Thu, Jun 4, 2015 at 4:02 PM, tester <tester@gmail.com> wrote:\n"\
        '> Â  Â  Â This is long thread test with return message.'
      expect(subject.body).to eq('message body')
    end
  end
end
