module Sorting
  PERMITTED_SORTING_PARAMS = [
    'created_at ASC',
    'created_at DESC',
    'updated_at ASC',
    'updated_at DESC'
  ].freeze

  private

  def sorting_param
    params[:sort] if permitted_sorting_params.include?(params[:sort])
  end

  def permitted_sorting_params
    PERMITTED_SORTING_PARAMS
  end
end
