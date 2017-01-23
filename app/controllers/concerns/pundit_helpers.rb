module PunditHelpers
  private

  def bulk_authorize(resources)
    resources.all? do |resource|
      authorize(resource)
    end
  end
end
