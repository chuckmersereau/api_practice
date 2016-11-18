module ParamsFilters
  extend ActiveSupport::Concern

  included do
    def filter_params
      params[:filters]
        .map { |k, v| { k.underscore.to_sym => v } }
        .reduce({}, :merge)
        .keep_if { |k, _| permited_filters.include? k }
    end
  end
end
