module Docs
  class AuthController < ::ApplicationController
    include ActionController::HttpAuthentication::Basic::ControllerMethods

    http_basic_authenticate_with name: 'superduper', password: 'Ce8*YfH7jPb*Gvb3N3fTekCx4z3rC9Yi'

    def login
      session[:doc_user] = 'superduper'
      redirect_to '/docs/graphiql'
    end
  end
end
