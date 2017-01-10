require 'spec_helper'

describe ActivityCommentSerializer do
  let(:activity_comment) do
    build(:activity_comment, person: build(:person))
  end

  subject { ActivityCommentSerializer.new(activity_comment).as_json }

  it { should include :body }
  it { should include :person_id }
  it { should include :person_name }
  it { should include :created_at }
  it { should include :updated_at }
  it { should include :updated_in_db_at }
end
