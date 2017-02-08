require 'rails_helper'

RSpec.describe AccountList::Analytics, type: :model do
  let(:user) { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let(:analytics) { AccountList::Analytics.new(account_list: account_list, start_date: 1.week.ago, end_date: Time.current) }

  def create_task(activity_type:, result: nil, next_action: nil)
    create(:task, account_list_id: account_list.id, activity_type: activity_type, result: result, next_action: next_action, completed: true, completed_at: 1.day.ago)
    # Analytics primarily reports on completed tasks, create uncomplete tasks so that we can test that they are not counted.
    create(:task, account_list_id: account_list.id, activity_type: activity_type, result: result, next_action: next_action, completed: false, completed_at: 1.day.ago)
  end

  before do
    # Appointments
    create_task(activity_type: 'Appointment', result: 'Completed')

    # Contacts
    contact = create(:contact, account_list: account_list)
    contact.contacts_that_referred_me << create(:contact, account_list: account_list)

    # Correspondence
    create_task(activity_type: 'Pre Call Letter', result: 'Done')
    create_task(activity_type: 'Reminder Letter', result: 'Done')
    create_task(activity_type: 'Support Letter', result: 'Done')
    create_task(activity_type: 'Thank', result: 'Done')

    # Electronic
    create_task(activity_type: 'Email', next_action: 'Appointment Scheduled')
    create_task(activity_type: 'Email', result: 'Received')
    create_task(activity_type: 'Facebook Message', result: 'Received')
    create_task(activity_type: 'Text Message', result: 'Received')
    create_task(activity_type: 'Email', result: 'Done')
    create_task(activity_type: 'Facebook Message', result: 'Done')
    create_task(activity_type: 'Text Message', result: 'Done')

    # Phone
    create_task(activity_type: 'Call', next_action: 'Appointment Scheduled')
    create_task(activity_type: 'Call', result: 'Attempted')
    create_task(activity_type: 'Call', result: 'Completed')
    create_task(activity_type: 'Call', result: 'Received')
    create_task(activity_type: 'Talk to In Person')
  end

  describe 'initialize' do
    it 'raises error if required arguments are not given' do
      expect { AccountList::Analytics.new }
        .to raise_error(ArgumentError)
        .with_message("account_list can't be blank, start_date can't be blank, end_date can't be blank")
    end

    it 'initializes successfully' do
      expect { AccountList::Analytics.new(account_list: account_list, start_date: 1.week.ago, end_date: Time.current) }.to_not raise_error
    end

    it 'parses string dates as iso8601' do
      analytics = AccountList::Analytics.new(account_list: account_list, start_date: 1.week.ago.iso8601, end_date: Time.current.iso8601)
      expect(analytics.start_date).to be_a Time
      expect(analytics.end_date).to be_a Time
      expect { AccountList::Analytics.new(account_list: account_list, start_date: 'hello', end_date: 'world') }.to raise_error(ArgumentError)
    end

    it 'accepts time objects' do
      analytics = AccountList::Analytics.new(account_list: account_list, start_date: 1.week.ago, end_date: Time.current)
      expect(analytics.start_date).to be_a Time
      expect(analytics.end_date).to be_a Time
    end
  end

  describe '#appointments' do
    subject { analytics.appointments }
    it 'returns count of completed appointment tasks' do
      expect(subject).to eq(completed: 1)
    end
  end

  describe '#contacts' do
    subject { analytics.contacts }
    it 'returns counts of contacts' do
      expect(subject).to eq(active: 2, referrals: 1, referrals_on_hand: 1)
    end
  end

  describe '#correspondence' do
    subject { analytics.correspondence }
    it 'returns counts of completed correspondence tasks' do
      expect(subject).to eq(precall: 1, reminders: 1, support_letters: 1, thank_yous: 1)
    end
  end

  describe '#electronic' do
    subject { analytics.electronic }
    it 'returns counts of electronic related tasks' do
      expect(subject).to eq(appointments: 1, received: 3, sent: 4)
    end
  end

  describe '#email' do
    subject { analytics.email }
    it 'returns counts of email related tasks' do
      expect(subject).to eq(received: 1, sent: 2)
    end
  end

  describe '#facebook' do
    subject { analytics.facebook }
    it 'returns counts of facebook related tasks' do
      expect(subject).to eq(received: 1, sent: 1)
    end
  end

  describe '#phone' do
    subject { analytics.phone }
    it 'returns counts of phone related tasks' do
      expect(subject).to eq(appointments: 1, attempted: 1, completed: 2, received: 1, talktoinperson: 1)
    end
  end

  describe '#text_message' do
    subject { analytics.text_message }
    it 'returns counts of text_message related tasks' do
      expect(subject).to eq(received: 1, sent: 1)
    end
  end
end
