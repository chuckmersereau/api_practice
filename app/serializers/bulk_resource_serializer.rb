class BulkResourceSerializer
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
      { id: resource.id }.as_json(args).merge(
        ErrorSerializer.new(hash: resource.errors, resource: resource, status: error_status_code(resource)).as_json(args)
      )
    else
      serializer = ActiveModel::Serializer.serializer_for(resource).new(resource)
      ActiveModelSerializers::Adapter.create(serializer).as_json(args)
    end
  end

  def error_status_code(resource)
    conflict_error?(resource) ? 409 : 400
  end

  def conflict_error?(resource)
    resource.errors[:updated_in_db_at].any? { |error| error.include?(ApplicationRecord::CONFLICT_ERROR_MESSAGE) }
  end
end
