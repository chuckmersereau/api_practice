Auth::Engine.routes.draw do
  get '/auth/donorhub/callback', to: 'provider/organization_accounts#create'
  get '/auth/google/callback', to: 'provider/google_accounts#create'
  get '/auth/mailchimp/callback', to: 'provider/mail_chimp_accounts#create'
  get '/auth/prayer_letters/callback', to: 'provider/prayer_letters_accounts#create'
  get '/auth/user/:provider', to: 'user_accounts#create'
  get '/auth/failure', to: 'user_accounts#failure'
end
