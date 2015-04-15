class TemplatesController < ApplicationController
  def template
    expires_in 15.minutes, public: true
    render template: 'angular/' + params[:path], layout: false
  end
end
