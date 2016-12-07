module Filtering
  private

  def filter_params
    return {} unless params[:filters]

    params[:filters]
      .map { |k, v| { k.underscore.to_sym => v } }
      .reduce({}, :merge)
      .keep_if { |k, _| permitted_filters.include? k }
  end
end
