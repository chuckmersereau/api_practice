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
          filter_params_with_id: permitted_filter_params_with_ids,
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

    describe 'JWT Authorize' do
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

    describe 'Update user tracked info' do
      context "the user's current_sign_in_at is recent" do
        before do
          api_login(user)
          user.update_columns(sign_in_count: 0, current_sign_in_at: 6.hours.ago)
        end

        it 'does not update the user tracked info for an authenticated user' do
          expect { get :index }.to_not change { user.reload.current_sign_in_at }
          expect(user.sign_in_count).to eq(0)
        end
      end

      context "the user's current_sign_in_at is a long time ago" do
        before do
          api_login(user)
          user.update_columns(sign_in_count: 0, current_sign_in_at: 1.week.ago)
        end

        it 'updates the user tracked info for an authenticated user' do
          travel_to(Time.current) do
            expect { get :index }.to change { user.reload.sign_in_count }.from(0).to(1)
            expect(user.current_sign_in_at).to eq(Time.current)
          end
        end
      end

      it 'does not update tracked fields if user is not authenticated' do
        user
        expect(User.count).to be_positive
        expect_any_instance_of(User).to_not receive(:update_tracked_fields!)
        expect_any_instance_of(User).to_not receive(:update_tracked_fields)
        get :index
      end
    end

    describe 'Filters' do
      let(:contact) { create(:contact) }
      let(:fake_contact_id) { SecureRandom.uuid }

      it 'allows a user to filter by id' do
        api_login(user)
        get :index, filter: { contact_id: contact.id }
        expect(response.status).to eq(200), invalid_status_detail
        expect(response_json[:filter_params][:contact_id]).to eq(contact.id)
        expect(response_json[:filter_params_with_id][:contact_id]).to eq(contact.id)
      end

      context '#date range' do
        it 'returns a 400 when a user tries to filter with an invalid date range' do
          api_login(user)
          get :index, filter: { time_at: '2016-20-12...2016-23-12' }
          expect(response.status).to eq(400), invalid_status_detail
          expect(response.body).to include(
            "Wrong format of date range for filter 'time_at', should follow 'YYYY-MM-DD...YYYY-MM-DD' for dates"
          )
        end
      end
    end

    describe 'Includes' do
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

      it 'sets the correct locale when specified in the accept-language header' do
        api_login(user)

        request.env['HTTP_ACCEPT_LANGUAGE'] = 'fr-FR,fr-CA;q=0.8'

        get :index
        expect(response_json[:current_locale]).to eq 'fr-FR'
      end

      it 'defaults to english when no preference is defined' do
        api_login(user)
        get :index
        expect(response_json[:current_locale]).to eq 'en-US'
      end

      it 'resets the locale constant to en-US in case of error' do
        api_login(italian_user)
        expect do
          get :index, raise_error: true
        end.to raise_error 'Test Error'
        expect(I18n.locale.to_s).to eq 'en-US'
      end
    end
  end
end
