class Person::GoogleAccount::ContactGroup < ActiveModelSerializers::Model
  attr_accessor :id, :title, :created_at, :updated_at

  def self.from_groups(groups, collection = [])
    groups.each do |group|
      collection.push(
        new(
          id: group.id,
          title: group.title,
          created_at: group.updated,
          updated_at: group.updated
        )
      )
    end
    collection
  end
end
