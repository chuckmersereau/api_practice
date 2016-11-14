require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  namespace :api do
    api_version(module: 'V2', header: { name: 'API-VERSION', value: 'v2' }, parameter: { name: 'version', value: 'v2' }, path: { value: 'v2' }) do
      resource :user, only: :show do
        scope module: :user do
          resource :authentication, only: :create
        end
      end
      resources :account_lists, only: [:index, :show, :update] do
        scope module: :account_lists do
          resources :donor_accounts, :designation_accounts, only: [:index, :show]
          resources :filters, only: [:index]
          resources :invites, only: [:index, :show, :create, :destroy]
          resources :users, only: [:index, :show, :destroy]
          resources :merge, only: [:create]
          resources :imports, only: [:show, :create]
          resource :prayer_letters_account, only: [:show, :create, :destroy] do
            get :sync, on: :member
          end
          resource :mail_chimp_account, only: [:show, :create, :destroy] do
            get :sync, on: :member
          end
          resources :notifications, only: [:index, :show, :create, :update, :destroy]
          resources :donations, only: [:index, :show, :create, :update]
        end
      end
      resource :user, only: [:show, :update] do
        resources :google_accounts, :key_accounts, :organization_accounts, module: :user
      end
    end
  end

  get 'monitors/lb' => 'monitors#lb'
  get 'monitors/sidekiq' => 'monitors#sidekiq'
  get 'monitors/commit' => 'monitors#commit'

  get '/mail_chimp_webhook/:token', to: 'mail_chimp_webhook#index'
  post '/mail_chimp_webhook/:token', to: 'mail_chimp_webhook#hook'
end
