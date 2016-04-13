class Admin::HomeController < ApplicationController
  def index
    @new_org = Organization.new(country: 'United States')
  end
end
