# This class takes care of adding tags and status interests to Mail Chimp
# This is needed to add those categories and tags to the contacts that will be exported to Mailchimp.
# For reference, see:
# https://developer.mailchimp.com/documentation/mailchimp/reference/lists/interest-categories/interests
class MailChimp::Exporter
  class InterestAdder
    attr_reader :mail_chimp_account, :gibbon_wrapper, :list_id

    def initialize(mail_chimp_account, gibbon_wrapper, list_id)
      @mail_chimp_account = mail_chimp_account
      @gibbon_wrapper = gibbon_wrapper
      @list_id = list_id
    end

    def add_tags_interests(tags_to_add)
      add_interests('Tags', :tags, tags_to_add)
    end

    def add_status_interests(statuses_to_add)
      add_interests('Partner Status', :statuses, statuses_to_add)
    end

    private

    def gibbon_list
      gibbon_wrapper.gibbon_list_object(list_id)
    end

    def add_interests(interest_category_name, attribute, interests_to_add)
      interest_category_id = mail_chimp_account.get_interest_attribute_for_list(group: attribute,
                                                                                attribute: :interest_category_id,
                                                                                list_id: list_id)

      interest_category = find_or_create_interest_category(interest_category_id, interest_category_name)
      interest_category_id = interest_category['id']
      mail_chimp_account.set_interest_attribute_for_list(group: attribute,
                                                         attribute: :interest_category_id,
                                                         list_id: list_id,
                                                         value: interest_category_id)

      interests = find_or_create_interests(interest_category_id, interests_to_add)
      mail_chimp_account.set_interest_attribute_for_list(group: attribute,
                                                         attribute: :interest_ids,
                                                         list_id: list_id,
                                                         value: interests)

      mail_chimp_account.save(validate: false)
      mail_chimp_account.reload
    end

    def find_or_create_interest_category(interest_category_id, interest_category_name)
      find_interest_category(interest_category_id, interest_category_name) ||
        create_interest_category(interest_category_name)
    end

    def find_interest_category(interest_category_id, interest_category_name)
      interest_categories = gibbon_list.interest_categories.retrieve(params: { 'count': '100' })['categories']
      interest_categories.find { |interest_category| interest_category['id'] == interest_category_id } ||
        interest_categories.find { |interest_category| interest_category['title'] == _(interest_category_name) }
    rescue Gibbon::MailChimpError => error
      raise unless does_not_have_interest_interests_enabled?(error)
    end

    def create_interest_category(group_type)
      interest_category_body = { title: _(group_type), type: 'hidden' }
      gibbon_list.interest_categories.create(body: interest_category_body)
      find_interest_category(nil, group_type)
    end

    def find_or_create_interests(interest_category_id, interests_to_add)
      interests_already_present = find_interests(interest_category_id)
      interests_created = create_interests(interest_category_id, interests_to_add - interests_already_present.keys)
      interests_already_present.merge(interests_created)
    end

    def find_interests(interest_category_id)
      gibbon_list.interest_categories(interest_category_id)
                 .interests
                 .retrieve(params: { fields: 'interests.id,interests.name', count: 60 })['interests']
                 .map { |interest| { interest['name'] => interest['id'] } }
                 .reduce({}, :merge) || {}
    end

    def create_interests(interest_category_id, interests)
      hash = {}
      interests.reject(&:blank?).each do |interest|
        begin
          interest = gibbon_list.interest_categories(interest_category_id).interests.create(body: { name: interest })
          hash[interest['name']] = interest['id']
        rescue Gibbon::MailChimpError => error
          break if maximum_number_of_interests_per_list?(error)
          raise unless already_exists_on_list?(error)
        end
      end
      hash
    end

    def does_not_have_interest_interests_enabled?(error)
      error.message.include?('code 211')
    end

    def already_exists_on_list?(error)
      error.status_code == 400 && error.detail =~ /Cannot add .* because it already exists on the list/
    end

    def maximum_number_of_interests_per_list?(error)
      error.status_code == 400 && error.detail =~ /Cannot have more than .* interests per list/
    end
  end
end
