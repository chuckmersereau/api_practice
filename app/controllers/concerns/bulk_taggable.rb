module BulkTaggable
  extend ActiveSupport::Concern

  included do
    skip_before_action :validate_and_transform_bulk_json_api_params
  end

  def tag_names
    params
      .require(:data)
      .collect { |hash| hash[:data][:attributes][:name] }
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
end
