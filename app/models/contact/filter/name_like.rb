class Contact::Filter::NameLike < Contact::Filter::Base
  class << self
    protected

    def execute_query(contacts, filters, _account_lists)
      if filters[:name_like].split(/\s+/).length > 1
        contacts.where("concat(first_name,' ',last_name) like ? ", "%#{filters[:name_like]}%")
      else
        contacts.where('first_name like :search OR last_name like :search', search: "#{filters[:name_like]}%")
      end
    end
  end
end
