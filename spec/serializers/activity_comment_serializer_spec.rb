require 'rails_helper'

describe ActivityCommentSerializer do
  let(:activity_comment) do
    build(:activity_comment, person: build(:person))
  end

  subject { ActivityCommentSerializer.new(activity_comment).as_json }

  it { should include :body }
  it { should include :person_name }
  it { should include :created_at }
  it { should include :updated_at }
  it { should include :updated_in_db_at }

  context 'person is nil' do
    let(:activity_comment) do
      build(:activity_comment, person: nil)
    end

    it { should include :body }
    it { should include :person_name }
    it { should include :created_at }
    it { should include :updated_at }
    it { should include :updated_in_db_at }
  end

  describe '#person_name' do
    it "returns the person's name" do
      expect(subject[:person_name]).to eq activity_comment.person.to_s
    end
  end

  describe '#body' do
    it 'returns the body' do
      expect(subject[:body]).to eq activity_comment.body
    end
  end
end
