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
  get 'preferences/imports', as: :network_preferences
  get 'preferences/imports/:tab_id', to: 'preferences#index', as: :network_preferences_tab
  get 'preferences/integrations', as: :integration_preferences
  get 'preferences/integrations/:tab_id', to: 'preferences#index', as: :integration_preferences_tab
  get 'preferences/accounts', as: :account_preferences
  get 'preferences/accounts/:tab_id', to: 'preferences#index', as: :account_preferences_tab

  # old preferences routes (SEO and external link upkeep)
  get '/preferences', to: redirect('preferences/personal'), as: :preferences
  get '/notifications', to: redirect('preferences/notifications'), as: :notifications
  get '/accounts', to: redirect('preferences/integrations/organization'), as: :accounts

  resources :preferences do
    collection do
      post :update_tab_order
      post :complete_welcome_panel
    end
  end

  resources :account_lists, only: :update

  resources :tags, only: [:create, :destroy]

  resources :social_streams, only: :index

  namespace :api do
    api_version(module: 'V2', header: { name: 'API-VERSION', value: 'v2' }, parameter: { name: 'version', value: 'v2' }, path: { value: 'v2' }) do
      resources :authentication, only: :create
      resources :account_lists, only: [:index, :show, :update] do 
        scope module: :account_lists do
          resources :designation_accounts, only: [:index, :show]
          resources :donor_accounts, only: [:index, :show]
          resources :filters, only: [:index]
          resources :invites, only: [:index, :show, :create, :destroy]
          resources :users, only: [:index, :show, :destroy]
          resources :merge, only: [:create]
          resources :imports, only: [:show, :create]
          resources :prayerletter_account, only: [:show, :create, :destroy] do
          member do
            get :sync
            end
          end
          resources :mailchimp_account, only: [:show, :create, :destroy] do
            member do
              get :sync
            end
          end
          resources :notifications, only: [:index, :show, :create, :update, :destroy]
          resources :donations, only: [:index, :show, :create, :update]
        end
      end
    end

    api_version(module: 'V1', header: { name: 'API-VERSION', value: 'v1' }, parameter: { name: 'version', value: 'v1' }, path: { value: 'v1' }) do
      resource :current_account_list, only: :show
      resources :constants, only: :index
      resources :donor_accounts, only: :index
      namespace :contacts do
        resources :filters, only: :index
        get 'export/primary', to: 'export#primary'
        get 'export/mailing', to: 'export#mailing'
        resources :tags, only: [:index] do
          collection do
            post :bulk_create
          end
        end
        get 'basic_list'
        get 'bulk_update_options'
        put 'bulk_update'
        post 'merge'
        delete 'tags' => 'tags#destroy'
      end
      resources :tags, :only => :index
      resources :contacts do
        collection do
          get :count
          get :tags
          delete :bulk_destroy
          get :assignable_send_newsletters
          get :assignable_statuses
          get :pledge_frequencies
          get :pledge_currencies
        end
        post 'save_referrals'
        scope module: :contacts do
          resources :donations, only: [] do
            collection do
              get :graph
            end
          end
          resources :referrals, only: :index
        end
      end
      namespace :tasks do
        get 'actions'
        get 'next_actions'
        get 'results'
      end
      resources :tasks do
        collection do
          get :count
        end
      end
      resources :designation_accounts, only: [:index]
      resources :donations
      resources :progress, only: [:index]
      resource :session, only: [:update]
      namespace :preferences do
        resources :notifications, only: :index
        resources :integrations, only: :index do
          collection do
            post :send_to_chalkline
          end
        end
        resources :imports, only: [:index, :create]
        resources :personal, only: :index
        resources :accounts, only: :index
        resources :contacts, only: :index
        namespace :accounts do
          resources :invites, only: [:index, :create, :destroy]
          resources :merges, only: [:index, :create]
          resources :users, only: [:index, :destroy]
        end
        namespace :integrations do
          resource :mail_chimp_account, only: [:show, :update, :destroy] do
            member do
              get :sync
            end
          end
          resource :prayer_letters_account, only: :destroy do
            member do
              get :sync
            end
          end
          resource :pls_account, only: :destroy do
            member do
              get :sync
            end
          end
          resources :google_accounts, only: :destroy
          resources :key_accounts, only: :destroy
          resources :organizations, only: :index
          resources :organization_accounts, only: [:index, :create, :update, :destroy]
        end
      end
      resources :people, only: [:index, :show] do
        collection do
          post 'merge'
        end
      end
      resource :preferences
      resources :users
      resources :appeals do
        resources :exclusions, only: [:index, :destroy], controller: :appeal_exclusions
      end
      resources :insights

      resources :mail_chimp_accounts, only: :destroy do
        collection do
          put :export_appeal_list
        end
      end

      namespace :reports do
        resource :balances, only: [:show]
        resource :expected_monthly_totals, only: [:show]
        resource :year_donations, only: [:show]
      end

      resources :filters, only: :index
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

  get '/close', to: 'auth#close', as: :application_close
  namespace :auth do
    get '/pls/callback', to: 'pls_accounts#create'
    get '/google/callback', to: 'google_accounts#create'
    get '/prayer_letters/callback', to: 'prayer_letters_accounts#create'
    get '/:provider/callback', to: 'accounts#create'
    get '/failure', to: 'accounts#failure'
    resources :accounts, except: [:index]
  end

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
      resources :reset, only: [:create]
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
