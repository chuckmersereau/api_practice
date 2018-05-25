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
      full_params[:include] = 'pledge_increase_contacts,pledge_increase_contacts.contact'
      full_params[:account_list_id] = account_list.id
    end

    it 'allows access to report' do
      api_login(coach)
      get :index, full_params
      expect(response.status).to eq(200), invalid_status_detail
    end

    it 'renders pledges and contacts with coach serializers' do
      api_login(coach)

      expect(Coaching::Reports::AppointmentResultsPeriodSerializer).to receive(:new).exactly(4).times.and_call_original
      expect(Coaching::ContactSerializer).to receive(:new).exactly(2).times.and_call_original

      get :index, full_params

      contact_json = response_json['included'].find { |json| json['id'] == contact.id }
      expect(contact_json).to_not be nil
    end
  end
end
