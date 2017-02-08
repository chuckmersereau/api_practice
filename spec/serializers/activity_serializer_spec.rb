require 'spec_helper'

describe ActivitySerializer do
  let(:activity) do
    build(:activity)
  end

  subject { ActivitySerializer.new(activity).as_json }

  it { should include :activity_type }
  it { should include :comments_count }
  it { should include :completed }
  it { should include :completed_at }
  it { should include :created_at }
  it { should include :due_date }
  it { should include :next_action }
  it { should include :no_date }
  it { should include :result }
  it { should include :starred }
  it { should include :start_at }
  it { should include :subject }
  it { should include :tag_list }
  it { should include :updated_at }
  it { should include :updated_in_db_at }
end
