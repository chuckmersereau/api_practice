module PunditHelpers
  private

  def bulk_authorize(resources, action = nil)
    resources.all? do |resource|
      authorize(resource, action)
    end
  end
end
