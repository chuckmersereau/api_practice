require 'spec_helper'

describe ApplicationHelper do
  describe 'date helper method' do
    before do
      helper.stub(:locale).and_return(:en)
    end
    it 'should output the right time zone for activity_comment.created_at' do # activity_comments/_comment.html.erb
      comment = create(:activity_comment)
      comment_str = comment.created_at.strftime('%-m/%-d/%y, %-l:%M %p')
      output = helper.l(comment.created_at)
      expect(comment_str).to eq(output)
    end
    it 'should output the right time zone for contact.notes_saved_at' do # contacts/_contact_body.html.erb & update.js.erb
      contact = create(:contact)
      notes_str = contact.notes_saved_at.strftime('%-m/%-d/%y, %-l:%M %p')
      output = helper.l(contact.notes_saved_at.to_datetime)
      expect(notes_str).to eq(output)

      output = helper.l(contact.notes_saved_at)
      expect(notes_str).to eq(output)
    end
    it 'should output the right time zone for home' do # home/_cultivate.html.erb
      task = create(:activity)
      task.completed_at = Time.zone.now
      task.save

      task_str = task.completed_at.strftime('%-m/%-d/%y, %-l:%M %p')
      output = helper.l(task.completed_at)
      expect(task_str).to eq(output)
    end
  end
end
