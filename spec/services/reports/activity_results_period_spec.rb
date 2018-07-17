require 'rails_helper'

RSpec.describe Reports::ActivityResultsPeriod, type: :model do
  let(:account_list) { create(:account_list) }
  let(:start_date) { Date.current.beginning_of_year }
  let(:end_date) { Date.current.end_of_day }
  let(:params) { { account_list: account_list, start_date: start_date, end_date: end_date } }

  # use method to bust caching inside of the report
  def report
    described_class.new(params)
  end

  def activity_state
    ::Task::TASK_ACTIVITIES.each do |activity_type|
      ::Task::REPORT_STATES.each do |state|
        yield(activity_type, state)
      end
    end
  end

  def create_activity(type:, completed:)
    completed_state = completed == 'completed'
    account_list.activities.create!(
      activity_type: type,
      completed: completed_state,
      subject: "Testing #{type} that is #{completed_state}"
    )
  end

  def create_numerous_activities(number, activity_type, completed)
    number.times do
      create_activity(type: activity_type, completed: completed)
    end
  end

  # This is not an optimal way of testing. Ideally, RSpec's describe/it block's
  # scoping would allow us to use the +activity_state+ block method to create
  # an +it+ spec for each +activity_type+ and it's +state+.
  describe 'activity counts' do
    it 'have correct counts' do
      activity_state do |activity_type, state|
        rand_number = rand(1..5)
        method_name = "#{state}_#{activity_type.parameterize.underscore.to_sym}"
        create_numerous_activities(rand_number, activity_type, state)
        expect(report.send(method_name)).to eq rand_number
      end
    end
  end
end
