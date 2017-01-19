class BulkUpdateSerializer
  def initialize(resources: [])
    @resources = resources
  end

  def as_json(*args)
    @resources.map do |resource|
      resource_or_error_json(resource, *args)
    end.as_json(*args)
  end

  private

  def resource_or_error_json(resource, args)
    if resource.errors.any?
      { id: resource.uuid }.as_json(args).merge(
        ErrorSerializer.new(hash: resource.errors, resource: resource, status: 400).as_json(args)
      )
    else
      serializer = ActiveModel::Serializer.serializer_for(resource).new(resource)
      ActiveModelSerializers::Adapter.create(serializer).as_json(args)
    end
  end
end
