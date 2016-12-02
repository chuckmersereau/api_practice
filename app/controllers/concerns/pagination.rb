module Pagination
  private

  def page_number_param
    params[:page] || 1
  end

  def per_page_param
    params[:per_page] || 25
  end

  def pagination_meta_params(resources)
    {
      page: page_number_param,
      per_page: per_page_param,
      total_count: resources.total_count,
      total_pages: resources.total_pages
    }
  end
end
