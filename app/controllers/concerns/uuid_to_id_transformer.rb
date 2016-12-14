# This module holds the logic necessary to allow clients to refer to unique universal identifiers (uuids) as ids. This is necessary,
# because it is a json api spec that uuids be sent in params[:id] by the client. Furthermore, because of the state of our database,
# a complete migration of integer based ids to uuids was not possible. It was therefore decided that foreign key uuid values contained
# in both params[:filter] and params[:data][:attributes] should be converted to their corresponding integer based ids at the controller
# level to allow models to function in the exact same way as before the use of uuids.

module UuidToIdTransformer
  private

  def transform_uuid_attributes_params_to_ids
    transform_uuids_to_ids_for_keys_in(params[:data][:attributes])
  end

  def transform_uuid_filters_params_to_ids
    transform_uuids_to_ids_for_keys_in(params[:filters])
  end

  def transform_uuids_to_ids_for_keys_in(param_location)
    return false unless param_location.present?
    param_location.keys.each do |key|
      change_specific_param_id_key_to_uuid(param_location, key) if uses_uuid?(key)
    end
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
    render json: { error: "Resource '#{key.chomp('_id')}' with id '#{param_location[key]}' does not exist." },
           status: 404
  end
end
