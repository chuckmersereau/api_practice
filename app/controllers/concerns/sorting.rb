module Sorting
  PERMITTED_SORTING_PARAMS = [
    'created_at ASC',
    'created_at DESC',
    'updated_at ASC',
    'updated_at DESC'
  ].freeze

  private

  def sorting_param
    params[:sort] if PERMITTED_SORTING_PARAMS.include?(params[:sort])
  end
end
