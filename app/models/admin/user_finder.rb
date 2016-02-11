class Admin::UserFinder < ActiveRecord::Base
  class << self
    def find_users(id_name_or_email)
      if id_name_or_email =~ /\d+/
        users_by_id(id_name_or_email)
      elsif id_name_or_email =~ /@/
        users_by_login_email(id_name_or_email)
      else
        users_by_name(id_name_or_email)
      end
    end

    private

    def users_by_id(id)
      User.where(id: id)
    end

    def users_by_login_email(email)
      User.where(id: user_id_by_relay(email) || user_id_by_key(email))
    end

    def users_by_name(name)
      if name.include?(',')
        last_name, first_name = name.split(',')
      else
        first_name, last_name = name.split
      end
      users_by_first_last(first_name, last_name)
    end

    def users_by_first_last(first_name, last_name)
      User.joins(:account_list_users)
        .where('lower(people.first_name) = ?', first_name.downcase.strip)
        .where('lower(people.last_name) = ?', last_name.downcase.strip)
        .uniq
    end

    def user_id_by_email(email)
      user_id_by_relay(email) || user_id_by_key(email)
    end

    def user_id_by_relay(email)
      Person::RelayAccount.where('lower(username) = ?', email.downcase)
        .try(:first).try(:person_id)
    end

    def user_id_by_key(email)
      Person::KeyAccount.where('lower(email) = ?', email.downcase)
        .try(:first).try(:person_id)
    end
  end
end
