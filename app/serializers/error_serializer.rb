class ErrorSerializer
  extend ActiveModel::Translation

  attr_reader :detail,
              :hash,
              :resource,
              :status,
              :title

  def initialize(detail: nil, hash: nil, resource: nil, status: nil, title: nil)
    @detail   = detail
    @hash     = hash
    @resource = resource
    @status   = status
    @title    = title

    after_initialize
  end

  def as_json(*args)
    @as_json ||= { errors: errors_data }.as_json(*args)
  end

  private

  def add_conflict_info_to_metadata(metadata, key, _error)
    metadata[:updated_in_db_at] = resource.updated_at&.utc&.iso8601 if key == :updated_in_db_at && resource.present?
  end

  def after_initialize
    unless status.present?
      raise ArgumentError,
            'must provide a status for the title response'
    end

    raise ArgumentError, error_data_validation_message unless resource.present? || title.present? || hash.present?
  end

  def error_data_validation_message
    'must provide at least an error title, resource instance, or hash of errors'
  end

  def errors_data
    @errors_data ||= formatted_hash_errors ||
                     formatted_resource_errors ||
                     formatted_title_error
  end

  def format_active_model_errors_object(errors_object)
    full_messages = errors_object.full_messages

    errors_object.map.with_index do |(key, error), index|
      full_message = full_messages[index]

      {
        status: status,
        source: { pointer: "/data/attributes/#{key}" },
        title: error,
        detail: full_message
      }.merge(generate_metadata(key, error))
    end
  end

  def formatted_hash_errors
    return unless hash.present? && hash.keys.any?

    mock_resource = OpenStruct.new(errors: ActiveModel::Errors.new(self))

    hash.each do |key, value|
      mock_resource.errors.add(key, value)
    end

    format_active_model_errors_object(mock_resource.errors)
  end

  def formatted_resource_errors
    return unless resource&.errors.present?

    format_active_model_errors_object(resource.errors)
  end

  def formatted_title_error
    return unless title

    detail_hash = detail.present? ? { detail: detail.to_s } : {}

    [
      {
        status: status,
        title: title
      }.merge!(detail_hash)
    ]
  end

  def generate_metadata(key, error)
    metadata = {}

    add_conflict_info_to_metadata(metadata, key, error)

    if metadata.any?
      { meta: metadata }
    else
      {}
    end
  end
end
