require 'sidekiq/web'
require 'sidekiq/cron/web'

UUID_REGEX = /[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/i.freeze

Rails.application.routes.draw do
  namespace :api do
    api_version(module: 'V2', path: { value: 'v2' }) do
      constraints(id: UUID_REGEX) do
        resources :account_lists, only: [:index, :show, :update] do
          scope module: :account_lists do
            resource :analytics, only: [:show]
            resources :designation_accounts, only: [:index, :show]
            resources :donations, only: [:index, :show, :create, :update]
            resources :donor_accounts, only: [:index, :show]
            resources :invites, only: [:index, :show, :create, :destroy]

            resources :imports, only: :show do
              scope module: :imports do
                collection do
                  resources :tnt, only: :create
                end
              end
            end

            resource :mail_chimp_account, only: [:show, :create, :destroy] do
              get :sync, on: :member
            end

            resources :merge, only: [:create]
            resources :notifications, only: [:index, :show, :create, :update, :destroy]

            resource :prayer_letters_account, only: [:show, :create, :destroy] do
              get :sync, on: :member
            end

            resources :users, only: [:index, :show, :destroy]
          end
        end

        resources :appeals, only: [:index, :show, :create, :update, :destroy] do
          scope module: :appeals do
            resources :contacts, only: [:index, :show, :destroy]
            resource :export_to_mailchimp, only: [:show], controller: :export_to_mailchimp
          end
        end

        namespace :constants do
          resources :organizations, only: [:index]
          resources :currencies, only: [:index]
          resources :notifications, only: [:index]
          resources :locales, only: [:index]
          resources :activities, only: [:index]
        end

        resources :contacts, only: [:index, :show, :create, :update, :destroy] do
          scope module: :contacts do
            collection do
              resource  :analytics, only: :show
              resources :filters, only: :index
              resources :merges, only: :create
              resources :tags, only: :index
              constraints(id: /.+/) do
                resources :duplicates, only: [:index, :destroy]
                namespace :people do
                  resources :duplicates, only: [:index, :destroy]
                end
              end
            end

            resources :addresses, only: [:index, :show, :create, :update, :destroy]

            resources :people, only: [:show, :index, :create, :update, :destroy] do
              scope module: :people do
                collection do
                  resources :merges, only: :create
                end

                resources :email_addresses, only: [:index, :show, :create, :update, :destroy]
                resources :facebook_accounts, only: [:index, :show, :create, :update, :destroy]
                resources :linkedin_accounts, only: [:index, :show, :create, :update, :destroy]
                resources :phones, only: [:index, :show, :create, :update, :destroy]
                resources :relationships, only: [:index, :show, :create, :update, :destroy]
                resources :twitter_accounts, only: [:index, :show, :create, :update, :destroy]
                resources :websites, only: [:index, :show, :create, :update, :destroy]
              end
            end

            resources :referrals, only: [:index, :show, :create, :update, :destroy]
            resources :referrers, only: [:index]
            resources :tags, only: [:create, :destroy], param: :tag_name, on: :member

            collection do
              get :analytics, to: 'analytics#show'
              resources :exports, only: :index
              resource :bulk, only: [:update, :destroy], controller: :bulk
              resources :filters, only: :index
            end
          end
        end

        resources :tasks do
          scope module: :tasks do
            resources :tags, only: [:create, :destroy], param: :tag_name, on: :member
          end

          collection do
            scope module: :tasks do
              resource :analytics, only: :show
              resource :bulk, only: [:update, :destroy], controller: :bulk
              resources :filters, only: :index
              resources :tags, only: :index
            end
          end
        end

        resource :user, only: [:show, :update] do
          scope module: :user do
            resource :authentication, only: :create

            resources :google_accounts
            resources :key_accounts
            resources :organization_accounts
          end
        end

        namespace :reports do
          resource :balances, only: :show
          resource :year_donations, only: :show
          resource :expected_monthly_totals, only: :show
        end
      end
    end
  end

  get 'monitors/commit',  to: 'monitors#commit'
  get 'monitors/lb',      to: 'monitors#lb'
  get 'monitors/sidekiq', to: 'monitors#sidekiq'

  get  'mail_chimp_webhook/:token', to: 'mail_chimp_webhook#index'
  post 'mail_chimp_webhook/:token', to: 'mail_chimp_webhook#hook'
end
