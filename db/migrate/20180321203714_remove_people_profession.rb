class RemovePeopleProfession < ActiveRecord::Migration
  def up
    TmpPerson.where.not(profession: nil).where(occupation: nil).find_each do |person|
      person.update_attribute(:occupation, person.profession)
    end

    remove_column :people, :profession
  end

  def down
    add_column :people, :profession, :text
  end
end

class TmpPerson < ActiveRecord::Base
  self.table_name = 'people'
end
