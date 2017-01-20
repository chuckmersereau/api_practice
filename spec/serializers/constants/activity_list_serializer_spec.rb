require 'spec_helper'

describe Constants::ActivityListSerializer do
  subject { Constants::ActivityListSerializer.new(activity_list) }
  let(:activity_list) { Constants::ActivityList.new }

  context '#activities' do
    it { expect(subject.activities).to be_an Array }

    it 'all elements should be strings' do
      subject.activities.each do |activity|
        expect(activity).to be_a(String)
      end
    end
  end
end
