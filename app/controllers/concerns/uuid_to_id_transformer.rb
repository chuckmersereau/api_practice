# This module holds the logic necessary to allow clients to refer to unique universal identifiers (uuids) as ids. This is necessary,
# because it is a json api spec that uuids be sent in params[:id] by the client. Furthermore, because of the state of our database,
# a complete migration of integer based ids to uuids was not possible. It was therefore decided that foreign key uuid values contained
# in both params[:filter] and params[:data][:attributes] should be converted to their corresponding integer based ids at the controller
# level to allow models to function in the exact same way as before the use of uuids.

module UuidToIdTransformer
  private

  def transform_uuid_attributes_params_to_ids
    if params[:data].is_a?(Array)
      params[:data].each do |updating_member|
        transform_uuids_to_ids_for_keys_in(updating_member[:data][:attributes])
      end
    else
      transform_uuids_to_ids_for_keys_in(params[:data][:attributes])
    end
  end

  def transform_uuid_filters_params_to_ids
    transform_uuids_to_ids_for_keys_in(filter_params_needing_transformation)
  end

  def filter_params_needing_transformation
    params[:filter]&.except(:account_list_id)
  end

  def transform_uuids_to_ids_for_keys_in(param_location)
    return false unless param_location.present?
    param_location.keys.each do |key|
      change_specific_param_id_key_to_uuid(param_location, key) if uses_uuid?(key)
      transform_uuids_to_ids_for_nested_resource(key, param_location[key]) if key.to_s.ends_with?('_attributes')
    end
  end

  def transform_uuids_to_ids_for_nested_resource(key, param_array)
    param_array.each do |param_hash|
      change_specific_param_id_key_to_uuid(param_hash, 'id', model_from_attributes_key(key)) if param_hash['id']
      transform_uuids_to_ids_for_keys_in(param_hash)
    end
  end

  def model_from_attributes_key(key)
    key.chomp('_attributes').singularize.camelize.constantize
  end

  def uses_uuid?(key)
    key.ends_with?('_id') &&
      ApplicationRecord.descendants.map(&:to_s).include?(model_name_from_key(key))
  end

  def change_specific_param_id_key_to_uuid(param_location, key, model = nil)
    return false unless param_location[key]
    model ||= model_name_from_key(key).constantize
    param_location[key] =
      get_id_from_model_and_key(param_location, key, model)
  end

  def model_name_from_key(key)
    key.chomp('_id').camelize
  end

  def get_id_from_model_and_key(param_location, key, model)
    model.where(uuid: param_location[key]).limit(1).ids.first
  rescue ActiveRecord::StatementInvalid
    raise ActiveRecord::RecordNotFound,
          "Resource '#{key.chomp('_id')}' with id '#{param_location[key]}' does not exist."
  end
end
