class Api::V2::BaseController < ApplicationController
  before_action :doorkeeper_authorize!
end
