class Admin::UserFinder
  class << self
    def find_users(id_name_or_email)
      if UUID_REGEX.match?(id_name_or_email)
        users_by_id(id_name_or_email)
      elsif id_name_or_email =~ /@/
        users_by_login_email(id_name_or_email)
      else
        users_by_name(id_name_or_email)
      end
    end

    def find_user_by_email(email)
      @users = users_by_login_email(email)
      return false if @users.count > 1
      @users.first
    end

    private

    def users_by_id(id)
      User.where(id: id)
    end

    def users_by_login_email(email)
      User.where(id: user_id_by_email(email))
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
          .where('lower(people.first_name) = ?', first_name.to_s.downcase.strip)
          .where('lower(people.last_name) = ?', last_name.to_s.downcase.strip)
          .uniq
    end

    def user_id_by_email(email)
      Person::KeyAccount.where('lower(email) = ?', email.downcase).pluck(:person_id)
    end
  end
end
