class StatusController < ApplicationController
  def index
    @north_star = NorthStarReport.new.weeks_with_history
  end
end
