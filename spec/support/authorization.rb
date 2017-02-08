require 'rails_helper'

shared_context :authorization do
  let(:authorization) { "Bearer #{JsonWebToken.encode(user_id: user.id)}" }
  header 'Authorization', :authorization
end
