require 'spec_helper'

shared_context :authorization do
  let(:authorization) { "Bearer #{user.access_token}" }
  header 'Authorization', :authorization
end
