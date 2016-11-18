module ParamsFilters
  extend ActiveSupport::Concern

  included do
    def filter_params
      params[:filter].keep_if { |k, _| permited_filters.include? k }.map{ |k, v| { k.to_sym => v } }.reduce({}, :merge)
    end
  end
end
