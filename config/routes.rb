require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  namespace :api do
    api_version(module: 'V2', header: { name: 'API-VERSION', value: 'v2' }, parameter: { name: 'version', value: 'v2' }, path: { value: 'v2' }) do
      resources :account_lists, only: [:index, :show, :update], path: 'account-lists' do
        scope module: :account_lists do
          resources :donor_accounts, only: [:index, :show], path: 'donor-accounts'
          resources :designation_accounts, only: [:index, :show], path: 'designation-accounts'
          resources :filters, only: [:index]
          resources :invites, only: [:index, :show, :create, :destroy]
          resources :users, only: [:index, :show, :destroy]
          resources :merge, only: [:create]
          resources :imports, only: [:show, :create]
          resource :prayer_letters_account, only: [:show, :create, :destroy], path: 'prayer-letters-account' do
            get :sync, on: :member
          end
          resource :mail_chimp_account, only: [:show, :create, :destroy], path: 'mail-chimp-account' do
            get :sync, on: :member
          end
          resources :notifications, only: [:index, :show, :create, :update, :destroy]
          resources :donations, only: [:index, :show, :create, :update]
        end
      end
      resources :appeals, only: [:index, :show, :create, :update, :destroy] do
        scope module: :appeals do
          resources :contacts, only: [:index, :show, :destroy]
          resource :export_to_mailchimp, only: [:show], controller: :export_to_mailchimp, path: 'export-to-mailchimp'
        end
      end
      resource :user, only: [:show, :update] do
        scope module: :user do
          resource :authentication, only: :create
          resources :google_accounts, path: 'google-accounts'
          resources :key_accounts, path: 'key-accounts'
          resources :organization_accounts, path: 'organization-accounts'
        end
      end
      resources :tasks do
        scope module: :tasks do
          resources :tags, only: [:create, :destroy], param: :tag_name, on: :member
          resources :analytics, only: :index
        end
      end
      resources :contacts do
        scope module: :contacts do
          resources :tags, only: [:create, :destroy], param: :tag_name, on: :member
          resources :addresses, only: [:index, :show, :create, :update, :destroy]
          resources :people do
            scope module: :people do
              resources :relationships, only: [:show, :index, :create, :update, :destroy]
            end
          end
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
