Auth::Engine.routes.draw do
  get '/google/callback', to: 'provider/google_accounts#create'
  get '/prayer_letters/callback', to: 'provider/prayer_letters_accounts#create'
  get '/user/:provider', to: 'user_accounts#create'
  get '/failure', to: 'user_accounts#failure'
end
