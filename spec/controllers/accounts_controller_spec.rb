require 'spec_helper'

describe AccountsController do
  describe 'when not signed in' do
    before do
      @user = create(:user_with_account)
      auth_hash = Hashie::Mash.new(uid: '5', credentials: { token: 'a', expires_at: 5 }, info: { first_name: 'John', last_name: 'Doe' })
      Person::FacebookAccount.find_or_create_from_auth(auth_hash, @user)
      request.env['omniauth.auth'] = auth_hash
    end
    it 'should sign a user in' do
      post 'create', provider: 'facebook'
      expect(request.session['warden.user.user.key']).to eq([[@user.id], nil])
    end

    it 'should queue data imports on sign in' do
      User.should_receive(:from_omniauth).and_return(@user)
      @user.should_receive(:queue_imports)
      post 'create', provider: 'facebook'
    end

    it 'redirects to the homepage if someone tries to connect to google without a session' do
      post 'create', provider: 'google'
      assert_redirected_to '/'
    end
  end

  describe 'when signed in' do
    before(:each) do
      @user = create(:user_with_account)
      sign_in(:user, @user)
    end

    describe 'GET index' do
      it 'should be successful' do
        get :index
        expect(response).to be_success
      end
    end

    describe "POST 'create'" do
      it 'signs out current user and create new user' do
        mash = Hashie::Mash.new(uid: '5', credentials: { token: 'a', expires_at: 5 }, info: { first_name: 'John', last_name: 'Doe' })
        request.env['omniauth.auth'] = mash
        expect do
          post 'create', provider: 'facebook', origin: 'login'
          expect(response).to redirect_to(setup_path(:org_accounts))
        end.to change(Person::FacebookAccount, :count).from(0).to(1)
        expect(subject.current_user).not_to eq @user
      end

      it 'creates an account' do
        mash = Hashie::Mash.new(uid: '5', credentials: { token: 'a', expires_at: 5 }, info: { first_name: 'John', last_name: 'Doe' })
        request.env['omniauth.auth'] = mash
        expect do
          post 'create', provider: 'facebook'
          expect(response).to redirect_to(accounts_path)
          expect(@user.facebook_accounts).to include(assigns(:account))
        end.to change(Person::FacebookAccount, :count).from(0).to(1)
      end

      it 'should redirect to social accounts if the user is in setup mode' do
        @user.update_attributes(preferences: { setup: true })
        Person::FacebookAccount.stub(:find_or_create_from_auth)
        post 'create', provider: 'facebook'
        expect(response).to redirect_to(setup_path(:social_accounts))
      end

      it 'should redirect to a stored user_return_to' do
        session[:user_return_to] = '/foo'
        Person::FacebookAccount.stub(:find_or_create_from_auth)
        post 'create', provider: 'facebook'
        expect(response).to redirect_to('/foo')
      end
    end

    describe "GET 'destroy'" do
      it 'returns http success' do
        @account = FactoryGirl.create(:facebook_account, person: @user)
        expect do
          get 'destroy', provider: 'facebook', id: @account.id
          expect(response).to redirect_to(accounts_path)
        end.to change(Person::FacebookAccount, :count).from(1).to(0)
      end
    end

    describe "GET 'failure'" do
      it 'redirects to index' do
        get 'failure'
        flash[:alert].should_not.nil?
        expect(response).to redirect_to(accounts_path)
      end
    end
  end
end
