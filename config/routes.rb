require 'sidekiq/web'
require 'sidekiq/cron/web'
require 'rollout_ui/server'

Rails.application.routes.draw do
  resources :google_integrations, only: [:show, :edit, :update, :create] do
    member do
      get :sync
    end
  end

  resources :help_requests, only: [:new, :create] do
    member do
      get :attachment
    end
  end

  get '/help' => 'help_requests#new'
  get '/preferences*path', to: 'preferences#index'
  get 'preferences/personal', as: :personal_preferences
  get 'preferences/personal/:tab_id', to: 'preferences#index', as: :personal_preferences_tab
  get 'preferences/notifications', as: :notification_preferences
  get 'preferences/notifications/:tab_id', to: 'preferences#index', as: :notification_preferences_tab
  get 'preferences/networks', as: :network_preferences
  get 'preferences/networks/:tab_id', to: 'preferences#index', as: :network_preferences_tab
  get 'preferences/integrations', as: :integration_preferences
  get 'preferences/integrations/:tab_id', to: 'preferences#index', as: :integration_preferences_tab

  # old preferences routes (SEO and external link upkeep)
  get '/preferences', to: redirect('preferences/personal'), as: :preferences
  get '/notifications', to: redirect('preferences/notifications'), as: :notifications
  get '/accounts', to: redirect('preferences/networks'), as: :accounts

  resources :account_lists, only: :update
  resources :prayer_letters_accounts, only: :create
  resources :pls_accounts, only: :create


  resources :tags, only: [:create, :destroy]

  resources :social_streams, only: :index

  namespace :api do
    api_version(module: 'V1', header: { name: 'API-VERSION', value: 'v1' }, parameter: { name: 'version', value: 'v1' }, path: { value: 'v1' }) do
      resources :contacts do
        collection do
          get :count
          get :tags
        end
      end
      resources :tasks do
        collection do
          get :count
        end
      end
      resources :donations, only: [:index]
      resources :progress, only: [:index]
      resources :preferences
      namespace :preferences do
        namespace :integrations do
          resource :mail_chimp, only: [:show, :update]
        end
      end
      resources :users
      resources :appeals do
        resources :exclusions, only: [:index, :destroy], controller: :appeal_exclusions
      end
      resources :insights

      resources :mail_chimp_accounts, only: :destroy do
        collection do
          put :export_appeal_list
          get :sync
        end
      end

      resources :prayer_letters_accounts, only: :destroy do
        collection do
          get :sync
        end
      end

      resources :pls_accounts, only: :destroy do
        collection do
          get :sync
        end
      end

      namespace :reports do
        resource :balances, only: [:show]
        resource :expected_monthly_totals, only: [:show]
        resource :year_donations, only: [:show]
      end
    end
    match '*all' => 'v1/base#cors_preflight_check', via: 'OPTIONS'
  end

  resources :imports do
    collection do
      get :sample
    end
    member do
      get :csv_preview_partial
    end
  end

  resources :activity_comments

  resources :account_lists do
    collection do
      get :sharing
      post :share
      post :merge
      post :remove_access
      post :cancel_invite
      get :accept_invite
      resource :account_reset, only: [:create]
    end
  end

  resources :appeals, only: [:show]

  resources :insights
  resources :donations
  resource :donation_syncs, only: [:create]
  resources :accounts, except: [:index]

  namespace :reports do
    resource :contributions, only: [:show]
    resource :balances, only: [:show]
    resource :expected_monthly_totals, only: [:show]
    resource :donor_currency_donations, only: [:show]
    resource :salary_currency_donations, only: [:show]
  end

  resources :contacts do
    collection do
      get :social_search
      put :bulk_update
      delete :bulk_destroy
      post :merge
      get  :find_duplicates
      put :not_duplicates
      post :send_to_chalkline
      get :add_multi
      post :save_multi
      get :mailing
    end
    member do
      get :add_referrals
      post :save_referrals
      get :details
      get :referrals
    end
    resources :people do
      collection do
        post :merge
      end
    end
  end

  resources :tasks do
    collection do
      delete :bulk_destroy
      put :bulk_update
    end
  end

  resources :people do
    collection do
      put :not_duplicates
      post :merge_sets
    end
  end

  resources :research, only: [:index] do
    member do
      get :search
    end
  end

  resources :setup

  namespace :person do
    resources :organization_accounts, only: [:new, :create, :edit, :update, :destroy]
  end

  resource :home, only: [:index], controller: :home do
    get 'index'
    get 'change_account_list'
    get 'download_data_check'
  end

  get 'privacy' => 'home#privacy'
  get 'login' => 'home#login'

  devise_for :users
  as :user do
    get '/logout' => 'sessions#destroy'
  end

  get 'monitors/lb' => 'monitors#lb'
  get 'monitors/sidekiq' => 'monitors#sidekiq'
  get 'monitors/commit' => 'monitors#commit'

  get '/auth/prayer_letters/callback', to: 'prayer_letters_accounts#create'
  get '/close', to: 'application#close', as: :application_close
  get '/auth/pls/callback', to: 'pls_accounts#create'
  get '/auth/:provider/callback', to: 'accounts#create'
  get '/auth/failure', to: 'accounts#failure'

  get '/mail_chimp_webhook/:token', to: 'mail_chimp_webhook#index'
  post '/mail_chimp_webhook/:token', to: 'mail_chimp_webhook#hook'


  def user_constraint(request, attribute)
    request.env['rack.session'] &&
      request.env['rack.session']['warden.user.user.key'] &&
      request.env['rack.session']['warden.user.user.key'][0] &&
      User.find(request.env['rack.session']['warden.user.user.key'][0].first)
          .public_send(attribute)
  end

  constraints -> (request) { user_constraint(request, :developer) || Rails.env.development? } do
    mount Sidekiq::Web => '/sidekiq'
    mount RolloutUi::Server => '/rollout'
  end

  constraints -> (request) { user_constraint(request, :admin) } do
    namespace :admin do
      resources :home, only: [:index]
      resources :offline_org, only: [:create]
      resources :impersonations, only: [:create]
    end
  end

  resources :status, only: :index

  get '/404', to: 'errors#error_404'
  get '/500', to: 'errors#error_500'

  get '/mobile', to: redirect(subdomain: 'm', path: '/')

  mount Peek::Railtie => '/peek'
  root to: 'home#index'

  get '/templates/:path.html' => 'templates#template', :constraints => { path: /.+/ }

  # See how all your routes lay out with "rake routes"
end
