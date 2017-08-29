class UserSerializer < ApplicationSerializer
  attributes :first_name,
             :last_name,
             :preferences

  has_many :account_lists
  has_many :email_addresses

  belongs_to :master_person

  def preferences
    object.preferences.merge(
      default_account_list: default_account_list_uuid,
      setup: object.setup)
  end

  private

  def default_account_list_uuid
    object.default_account_list_record.try(:uuid)
  end
end
