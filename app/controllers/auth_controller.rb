class AuthController < ApplicationController
  def close
    render layout: false
  end
end
