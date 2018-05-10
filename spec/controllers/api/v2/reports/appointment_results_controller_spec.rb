require 'rails_helper'

RSpec.describe Api::V2::Reports::AppointmentResultsController, type: :controller do
  let(:user)         { create(:user_with_account) }
  let(:account_list) { user.account_lists.order(:created_at).first }

  let(:given_serializer_class) { Reports::AppointmentResultsPeriodSerializer }
  let(:given_resource_type) { 'reports_appointment_results_periods' }
  let(:factory_type) { :account_list }
  let(:resource) do
    Reports::AppointmentResultsPeriod.new(account_list: account_list, start_date: 1.week.ago, end_date: DateTime.now)
  end

  let(:correct_attributes) { {} }

  include_examples 'index_examples', except: [:sorting, :pagination]

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

    it 'sends averages of values in AppointmentResultsPeriod objects' do
      api_login(user)
      get :index, filter: { account_list_id: account_list.id }

      expect(averages.keys).to match_array %w(average_individual_appointments
                                              average_group_appointments
                                              average_new_monthly_partners
                                              average_new_special_pledges
                                              average_monthly_increase
                                              average_pledge_increase)
    end

    it 'sends only meta for requested fields' do
      api_login(user)
      get :index,
          filter: { account_list_id: account_list.id },
          fields: { reports_appointment_results_periods: 'individual_appointments,group_appointments' }

      expect(averages.keys).to eq %w(average_individual_appointments average_group_appointments)
    end
  end
end
