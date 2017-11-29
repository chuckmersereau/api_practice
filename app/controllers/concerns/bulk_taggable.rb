module BulkTaggable
  extend ActiveSupport::Concern

  included do
    skip_before_action :validate_and_transform_bulk_json_api_params
  end

  def tag_names
    params
      .require(:data)
      .collect(&method(:extract_tag_name))
  end

  def taggable_ids
    tags_scope.tagged_with(tag_names, any: true).ids.uniq
  end

  def tags_scope
    raise NotImplementedError, 'must implement this in the controller directly'
  end

  private

  def missing_id_error
    # This method is a no-op because we do not care about IDs for tags
  end

  def extract_tag_name(hash)
    name = hash.dig(:data, :attributes, :name)
    return name if name.is_a?(String)

    type = type_name(name)
    raise Exceptions::BadRequestError,
          format('Expected tag name to be a string, but it was %s %s with a value of %p',
                 type.indefinite_article, type, name)
  end

  def type_name(object)
    if object.is_a?(Hash) || object.is_a?(ActionController::Parameters)
      'object'
    else
      name.class.name.downcase
    end
  end
end
