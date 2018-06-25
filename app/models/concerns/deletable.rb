# frozen_string_literal: true

module Deletable
  extend ActiveSupport::Concern

  included do
    attr_accessor :deleted_by

    # disabling because we want to retain the foreign_key id, but I'm not
    # yet sure what should be passed to +dependent+ to retain the default
    # setting. I removed the dependent for now, until I figure that.
    has_many :deleted_records, as: :deletable # rubocop:disable Rails/HasManyOrHasOneDependent
    before_destroy :save_to_deleted_records_table
  end

  private

  def save_to_deleted_records_table
    deleted_records.create!(
      deleted_by: deleted_by,
      deleted_at: ::Time.current,
      deleted_from_id: deleted_from.id,
      deleted_from_type: deleted_from.class.to_s
    )
  end
end
