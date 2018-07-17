require 'rails_helper'

RSpec.describe Api::V2::Reports::ActivityResultsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  let(:given_serializer_class) { Reports::ActivityResultsPeriodSerializer }
  let(:given_resource_type) { 'reports_activity_results_periods' }
  let(:factory_type) { :account_list }
  let(:resource) do
    Reports::ActivityResultsPeriod.new(account_list: account_list,
                                       start_date: 1.week.ago,
                                       end_date: DateTime.current)
  end

  let(:correct_attributes) { {} }

  describe 'index' do
    before do
      contact = create(:contact, account_list: account_list)
      account_list.primary_appeal = create(:appeal)
      create(:pledge, contact: contact, appeal: account_list.primary_appeal)
    end

    include_examples 'index_examples', except: [:sorting, :pagination]
  end

  describe 'Filters' do
    it 'allows a user to request from their account_list' do
      api_login(user)
      get :index, filter: { account_list_id: account_list.id }
      expect(response.status).to eq 200
    end

    it 'blocks a user from accessing others account lists' do
      api_login(create(:user))
      get :index, filter: { account_list_id: account_list.id }
      expect(response.status).to eq 404
    end
  end

  describe 'meta' do
    let(:averages) { response_json['meta']['averages'] }

    it 'sends averages of values in ActivityResultsPeriod objects' do
      api_login(user)
      get :index, filter: { account_list_id: account_list.id }

      expect(averages.keys).to match_array %w(average_completed_appointment
                                              average_completed_call
                                              average_completed_email
                                              average_uncompleted_text_message
                                              average_uncompleted_thank
                                              average_uncompleted_to_do
                                              average_completed_facebook_message
                                              average_completed_letter
                                              average_uncompleted_support_letter
                                              average_uncompleted_talk_to_in_person
                                              average_completed_newsletter_email
                                              average_completed_newsletter_physical
                                              average_uncompleted_pre_call_letter
                                              average_uncompleted_reminder_letter
                                              average_completed_prayer_request
                                              average_completed_pre_call_letter
                                              average_uncompleted_newsletter_physical
                                              average_uncompleted_prayer_request
                                              average_completed_reminder_letter
                                              average_completed_support_letter
                                              average_uncompleted_letter
                                              average_uncompleted_newsletter_email
                                              average_completed_talk_to_in_person
                                              average_completed_text_message
                                              average_uncompleted_call
                                              average_uncompleted_email
                                              average_uncompleted_facebook_message
                                              average_completed_thank
                                              average_completed_to_do
                                              average_uncompleted_appointment)
    end

    it 'sends only meta for requested fields' do
      api_login(user)
      get :index,
          filter: { account_list_id: account_list.id },
          fields: { reports_activity_results_periods: 'completed_call,completed_email' }

      expect(averages.keys).to eq %w(average_completed_call average_completed_email)
    end
  end

  context 'as coach' do
    include_context 'common_variables'

    let(:coach) { create(:user).becomes(User::Coach) }
    let(:contact) do
      create(:contact, account_list: account_list,
                       created_at: 4.months.ago,
                       status: 'Call for Appointment',
                       pledge_amount: nil)
    end

    before do
      travel_to(1.week.ago) { contact.update(status: 'Partner - Financial', pledge_amount: 100) }

      account_list.coaches << coach
      full_params[:account_list_id] = account_list.id
    end

    it 'allows access to report' do
      api_login(coach)
      get :index, full_params
      expect(response.status).to eq(200), invalid_status_detail
    end
  end
end
