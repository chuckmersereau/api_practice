class UserSerializer < PersonSerializer
  attributes :preferences
  has_many :account_lists

  belongs_to :master_person

  def person_exhibit
    exhibit(object.becomes(Person))
  end

  def preferences
    object.preferences.merge(
      default_account_list: object.default_account_list_record.try(:id),
      setup: object.setup
    )
  end
end
