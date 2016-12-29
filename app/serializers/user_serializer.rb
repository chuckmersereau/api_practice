class UserSerializer < ApplicationSerializer
  attributes :first_name,
             :last_name,
             :preferences

  has_many :account_lists

  belongs_to :master_person

  def preferences
    object.preferences.merge(default_account_list: default_account_list_uuid)
  end

  private

  def default_account_list_uuid
    AccountList.where(id: object.default_account_list)
               .limit(1)
               .pluck(:uuid)
               .first
  end
end
