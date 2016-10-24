require 'sidekiq/web'
require 'sidekiq/cron/web'
require 'rollout_ui/server'

Rails.application.routes.draw do
  namespace :api do
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

  get 'login' => 'home#login'

  devise_for :users
  as :user do
    get '/logout' => 'sessions#destroy'
  end

  mount Peek::Railtie => '/peek'

  # See how all your routes lay out with "rake routes"
end
