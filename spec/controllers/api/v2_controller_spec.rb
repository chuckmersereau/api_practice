require 'rails_helper'

describe Api::V2Controller do
  include_examples 'common_variables'

  let(:user)          { create(:user_with_account) }
  let(:account_list)  { create(:account_list) }
  let(:response_json) { JSON.parse(response.body).deep_symbolize_keys }

  describe 'controller callbacks' do
    controller(Api::V2Controller) do
      skip_after_action :verify_authorized

      resource_type :contacts

      def index
        raise 'Test Error' if params[:raise_error] == true
        render json: {
          filter_params: filter_params,
          include_params: include_params,
          current_time_zone: current_time_zone.name,
          current_locale: I18n.locale
        }
      end

      def create
        render json: params[:test][:attributes] || {}
      end

      def update
        render json: params[:test][:attributes] || {}
      end

      private

      def permitted_filters
        [:contact_id, :time_at]
      end
    end

    context '#jwt_authorize' do
      it 'doesnt allow not signed in users to access the api' do
        get :index
        expect(response.status).to eq(401), invalid_status_detail
      end

      it 'allows signed_in users with a valid token to access the api' do
        api_login(user)
        get :index
        expect(response.status).to eq(200), invalid_status_detail
      end
    end

    context '#filters' do
      let(:contact) { create(:contact) }

      it 'allows a user to filter by id using a uuid' do
        api_login(user)
        get :index, filter: { contact_id: contact.uuid }
        expect(response.status).to eq(200), invalid_status_detail
        expect(response_json[:filter_params][:contact_id]).to eq(contact.id)
      end

      it 'returns a 404 when a user tries to filter with the id of a resource' do
        api_login(user)
        get :index, filter: { contact_id: contact.id }
        expect(response.status).to eq(404), invalid_status_detail
        expect(response.body).to include("Resource 'contact' with id '#{contact.id}' does not exist")
      end

      it 'returns a 404 when a user tries to filter with a resource that does not exist' do
        api_login(user)
        get :index, filter: { contact_id: 'AXXSAASA222Random' }
        expect(response.status).to eq(404), invalid_status_detail
        expect(response.body).to include("Resource 'contact' with id 'AXXSAASA222Random' does not exist")
      end

      context '#date range' do
        it 'returns a 400 when a user tries to filter with an invalid date range' do
          api_login(user)
          get :index, filter: { time_at: '2016-20-12...2016-23-12' }
          expect(response.status).to eq(400), invalid_status_detail
          expect(response.body).to include("Wrong format of date range for filter 'time_at', should follow 'YYYY-MM-DD...YYYY-MM-DD' for dates")
        end
      end
    end

    context '#includes' do
      let(:contact) { create(:contact) }

      it "includes all associated resources when the '*' flag is passed" do
        api_login(user)
        get :index, include: '*'
        expect(response.status).to eq(200), invalid_status_detail
        expect(response_json[:include_params]).to eq(ContactSerializer._reflections.keys.map(&:to_s))
      end
    end

    context 'Timezone specific requests' do
      before { travel_to(Time.local(2017, 1, 1, 12, 0, 0)) }
      after { travel_back }

      context 'When the user has a specified Time Zone' do
        let(:zone) do
          ActiveSupport::TimeZone.all.detect { |zone| Time.zone != zone }
        end

        let(:user) do
          create(:user).tap do |user|
            user.assign_time_zone(zone)
          end
        end

        it "returns the correct time in the user's timezone" do
          api_login(user)
          get :index

          expect(response.status).to eq(200), invalid_status_detail

          expect(response_json[:current_time_zone]).to     eq zone.name
          expect(response_json[:current_time_zone]).not_to eq Time.zone.name
        end
      end

      context "When the user doesn't have a specified Time Zone" do
        let(:user) do
          create(:user).tap do |user|
            preferences = user.preferences
            preferences[:time_zone] = nil

            user.preferences = preferences
          end
        end

        it "returns the application's Time Zone" do
          api_login(user)
          get :index

          expect(response.status).to eq(200), invalid_status_detail
          expect(response_json[:current_time_zone]).to eq Time.zone.name
        end
      end
    end

    context 'Locale specific requests' do
      let(:italian_user) { create(:user, locale: 'it') }

      it 'sets the correct locale defined in user preferences' do
        api_login(italian_user)
        get :index
        expect(response_json[:current_locale]).to eq 'it'
      end

      it 'defaults to english when no preference is defined' do
        api_login(user)
        get :index
        expect(response_json[:current_locale]).to eq 'en-US'
      end

      it 'resets the locale constant to nil in case of error' do
        api_login(italian_user)
        expect do
          get :index, raise_error: true
        end.to raise_error 'Test Error'
        expect(I18n.locale.to_s).to eq 'en-US'
      end
    end
  end
end
