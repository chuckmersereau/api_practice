class MovePrefBlogForeignKeys < ActiveRecord::Migration
  def up
    after = 1.week.ago if Rails.env.production?

    TmpUser.move_default_account_list_ids(after)
    TmpAccountList.move_salary_organization_ids(after)

    rename_column :people, :default_account_list_id_holder, :default_account_list
    rename_column :account_lists, :salary_organization_id_holder, :salary_organization_id
  end

  def down
    rename_column :people, :default_account_list, :default_account_list_id_holder
    rename_column :account_lists, :salary_organization_id, :salary_organization_id_holder
  end
end

class TmpUser < ActiveRecord::Base
  self.table_name = 'people'
  self.primary_key = 'id'

  store :preferences

  def self.move_default_account_list_ids(after)
    scope = where("preferences like '%default_account_list: %'").where(default_account_list_id_holder: nil)
    scope = scope.where('updated_at > ?', after) if after
    p @i = scope.count
    scope.find_each do |user|
      @i -= 1
      p @i if @i % 500 == 0
      id = user.preferences[:default_account_list]
      user.update_column(:default_account_list_id_holder, id) if id
    end
  end
end

class TmpAccountList < ActiveRecord::Base
  self.table_name = 'account_lists'
  self.primary_key = 'id'

  store :settings

  def self.move_salary_organization_ids(after)
    scope = where("settings like '%salary_organization_id: %'")
    scope = scope.where('updated_at > ?', after) if after
    p @i = scope.count
    scope.find_each do |al|
      @i -= 1
      p @i if @i % 500 == 0
      id = al.settings[:salary_organization_id]
      al.update_column(:salary_organization_id_holder, id) if id
    end
  end
end
