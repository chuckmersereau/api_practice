require 'rails_helper'

describe ActivityCommentSerializer do
  let(:activity_comment) do
    build(:activity_comment, person: build(:person))
  end

  subject { ActivityCommentSerializer.new(activity_comment).as_json }

  describe '#body' do
    it 'returns the body' do
      expect(subject[:body]).to eq activity_comment.body
    end
  end
end
