require 'rails_helper'

RSpec.describe Api::V2::AccountLists::AnalyticsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.first }
  let!(:task_one) do
    create(:task, account_list: account_list, activity_type: 'Talk to In Person',
                  completed: true, completed_at: 6.days.ago)
  end
  let!(:task_two) do
    create(:task, account_list: account_list, activity_type: 'Talk to In Person',
                  completed: true, completed_at: 3.weeks.ago)
  end

  let(:resource) do
    AccountList::Analytics.new(
      account_list: account_list,
      start_date: 1.month.ago,
      end_date: Time.current
    )
  end

  let(:given_reference_key) { 'appointments' }

  let(:parent_param) { { account_list_id: account_list.uuid } }

  include_examples 'show_examples', except: [:sparse_fieldsets]

  context 'filtering by date_range' do
    let(:incorrect_datetime_range) { "#{1.week.ago.iso8601}...#{Time.current.iso8601}" }
    let(:incorrect_date_range) { "#{1.week.ago.iso8601}...#{Time.current.iso8601}" }
    let(:full_params) do
      {
        filter: {
          date_range: range
        },
        account_list_id: account_list.uuid
      }
    end

    context 'with a valid datetime or date range' do
      context 'with date and time' do
        let(:range) { "#{1.week.ago.utc.iso8601}...#{Time.current.utc.iso8601}" }

        it 'filters out tasks that are not in the specified date range' do
          api_login(user)
          get :show, full_params
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)['data']['attributes']['phone']['talktoinperson']).to eq(1)
        end
      end

      context 'with date only' do
        let(:range) { "#{1.week.ago.utc.to_date}...#{Time.current.utc.to_date}" }

        it 'filters out tasks that are not in the specified date range' do
          api_login(user)
          get :show, full_params
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)['data']['attributes']['phone']['talktoinperson']).to eq(1)
        end
      end
    end

    context 'with an invalid datetime or date range' do
      context 'with date and time' do
        let(:range) { '9999-99-99T99:99:99Z...9999-99-99T99:99:99Z' }

        it 'raises a bad_request error when the datetime range follows the wrong format' do
          api_login(user)
          get :show, full_params
          expect(response.status).to eq(400), invalid_status_detail
        end
      end

      context 'with date only' do
        let(:range) { '10/12/2015...10/12/2016' }

        it 'raises a bad_request error when the datetime range follows the wrong format' do
          api_login(user)
          get :show, full_params
          expect(response.status).to eq(400)
        end
      end
    end
  end
end
