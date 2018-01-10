require 'sidekiq/pro/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  mount Auth::Engine, at: '/', constraints: { subdomain: 'auth' }

  authenticated :user, ->(u) { u.developer } do
    mount Sidekiq::Web => '/sidekiq'
  end

  namespace :api do
    post :graphql, to: 'graphql#create'

    api_version(module: 'V2', path: { value: 'v2' }) do
      constraints(id: UUID_REGEX) do
        namespace :admin do
          resources :impersonation, only: :create
          resources :organizations, only: :create
          resources :resets, only: :create
        end
        resources :account_lists, only: [:index, :show, :update] do
          scope module: :account_lists do
            resource :analytics, only: [:show]
            resources :designation_accounts, only: [:index, :show]
            resources :donations, only: [:index, :show, :create, :update, :destroy]
            resources :donor_accounts, only: [:index, :show]
            resources :invites, only: [:index, :show, :create, :destroy] do
              put :accept, on: :member, action: :update
            end

            resources :imports, only: :show do
              scope module: :imports do
                collection do
                  resources :tnt, only: :create
                  resources :google, only: :create
                  resources :tnt_data_sync, only: :create
                  resources :csv, only: [:index, :show, :create, :update]
                end
              end
            end

            resource :mail_chimp_account, only: [:show, :create, :destroy] do
              get :sync, on: :member
            end

            resources :merge, only: [:create]
            resources :notification_preferences, only: [:index, :show, :create, :destroy]
            resources :notifications, only: [:index, :show, :create, :update, :destroy]
            resources :pledges, only: [:index, :show, :create, :update, :destroy]

            resource :prayer_letters_account, only: [:show, :create, :destroy] do
              get :sync, on: :member
            end

            resources :users, only: [:index, :show, :destroy]
            resources :coaches, only: [:index, :show, :destroy]

            resource :chalkline_mail, only: :create
          end
        end

        resources :appeals, only: [:index, :show, :create, :update, :destroy] do
          scope module: :appeals do
            resources :appeal_contacts, only: [:index, :show, :create, :destroy]
            resources :excluded_appeal_contacts, only: [:index, :show, :destroy]
          end
        end

        resources :background_batches, except: [:update]

        namespace :coaching do
          resources :account_lists, only: [:index, :show]
          resources :contacts, only: [:index, :show]
          resources :pledges, only: [:index, :show]
        end

        resources :constants, only: [:index]

        resources :contacts, only: [:index, :show, :create, :update, :destroy] do
          scope module: :contacts do
            collection do
              post :export_to_mail_chimp, to: 'export_to_mail_chimp#create'
              resource  :analytics, only: :show
              resources :filters, only: :index
              resources :merges, only: :create
              namespace :merges do
                resource :bulk, only: [:create], controller: :bulk
              end
              resources :tags, only: :index
              namespace :tags do
                resource :bulk, only: [:create, :destroy], controller: :bulk
              end
              constraints(id: /.+/) do
                resources :duplicates, only: [:index, :show, :update]
                namespace :people do
                  resources :duplicates, only: [:index, :show, :update]
                end
              end
              namespace :people do
                resource :bulk, only: [:create, :update, :destroy], controller: :bulk
                namespace :merges do
                  resource :bulk, only: [:create], controller: :bulk
                end
              end
            end

            resources :addresses, only: [:index, :show, :create, :update, :destroy]
            resources :donation_amount_recommendations, only: [:index, :show, :create, :update, :destroy]

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
            resources :tags, only: [:create, :destroy], param: :tag_name

            collection do
              get :analytics, to: 'analytics#show'
              resources :exports, only: :index do
                collection do
                  scope module: :exports do
                    resources :mailing, only: :index
                  end
                end
              end
              resource :bulk, only: [:create, :update, :destroy], controller: :bulk
              resources :filters, only: :index
              resources :people, only: [:index, :show, :update, :destroy]
            end
          end
        end

        resources :tasks do
          scope module: :tasks do
            resources :tags, only: [:create, :destroy], param: :tag_name
            resources :comments, only: [:index, :show, :create, :update, :destroy]
          end

          collection do
            scope module: :tasks do
              resource :analytics, only: :show
              resource :bulk, only: [:create, :update, :destroy], controller: :bulk
              resources :filters, only: :index
              resources :tags, only: :index
              namespace :tags do
                resource :bulk, only: [:create, :destroy], controller: :bulk
              end
            end
          end
        end

        resource :user, only: [:show, :update] do
          scope module: :user do
            resource :authenticate, only: :create
            resources :google_accounts do
              scope module: :google_accounts do
                resources :google_integrations do
                  get :sync, on: :member
                end
              end
            end
            resources :key_accounts
            resources :organization_accounts
          end
        end

        namespace :reports do
          resource :balances, only: :show
          resource :donation_monthly_totals, only: :show
          resource :donor_currency_donations, only: :show
          resource :expected_monthly_totals, only: :show
          resource :goal_progress, only: :show
          resource :monthly_giving_graph, only: :show
          resource :salary_currency_donations, only: :show
          resource :year_donations, only: :show

          resources :monthly_losses_graphs, only: :show
        end

        namespace :tools do
          get :analytics, to: 'analytics#show'
        end
      end
      resource :user, only: [] do
        scope module: :user do
          resources :options
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
