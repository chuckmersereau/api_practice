require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
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
  end

  get 'monitors/lb' => 'monitors#lb'
  get 'monitors/sidekiq' => 'monitors#sidekiq'
  get 'monitors/commit' => 'monitors#commit'

  get '/mail_chimp_webhook/:token', to: 'mail_chimp_webhook#index'
  post '/mail_chimp_webhook/:token', to: 'mail_chimp_webhook#hook'
end
