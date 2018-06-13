require 'rails_helper'
describe TaskExhibit do
  subject { TaskExhibit.new(task, context) }
  let(:task) { build(:task) }
  let(:context) { double }

  context '#css_class' do
    it 'should return high when start_at time is past' do
      task.start_at = 1.hour.ago
      expect(subject.css_class).to eql('high')
    end

    it 'should return mid when start_at time is in the next day' do
      task.start_at = 1.hour.from_now
      expect(subject.css_class).to eql('mid')
    end

    it 'should return nothing when start_at time over a day old' do
      task.start_at = 1.week.from_now
      expect(subject.css_class).to eql('')
    end
  end
end
