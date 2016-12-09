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

  def after_initialize
    unless status.present?
      raise ArgumentError,
            'must provide a status for the title response'
    end

    unless resource.present? || title.present? || hash.present?
      raise ArgumentError, error_data_validation_message
    end
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
      }
    end
  end

  def formatted_hash_errors
    return unless hash.present? && hash.keys.count.positive?

    mock_resource = OpenStruct.new(errors: ActiveModel::Errors.new(self))

    hash.each do |key, value|
      mock_resource.errors.add(key, value)
    end

    format_active_model_errors_object(mock_resource.errors)
  end

  def formatted_resource_errors
    return unless resource && !resource.valid?

    format_active_model_errors_object(resource.errors)
  end

  def formatted_title_error
    return unless title

    detail_hash = detail.present? ? { detail: detail } : {}

    [
      {
        status: status,
        title: title
      }.merge!(detail_hash)
    ]
  end

  def error_data_validation_message
    'must provide at least an error title, resource instance, or hash of errors'
  end
end
