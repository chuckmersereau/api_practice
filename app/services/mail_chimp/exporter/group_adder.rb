# This class takes care of adding tags and satus interest groups to the Mail Chimp side of the sync.
# This is needed to add those categories and tags to the contacts that will be exported to Mailchimp.
# For reference, see:
# https://developer.mailchimp.com/documentation/mailchimp/reference/lists/interest-categories/interests
class MailChimp::Exporter
  class GroupAdder
    attr_reader :mail_chimp_account, :gibbon_wrapper, :list_id

    def initialize(mail_chimp_account, gibbon_wrapper, list_id)
      @mail_chimp_account = mail_chimp_account
      @gibbon_wrapper = gibbon_wrapper
      @list_id = list_id
    end

    def add_tags_groups(tags_to_add)
      add_groups('Tags', :tags, tags_to_add)
    end

    def add_status_groups(statuses_to_add)
      add_groups('Partner Status', :statuses, statuses_to_add)
    end

    private

    def add_groups(group_name, attribute, groups_to_add)
      interest_group_id = mail_chimp_account.get_interest_attribute_for_list(group: attribute,
                                                                             attribute: :interest_category_id,
                                                                             list_id: list_id)
      grouping = find_grouping(interest_group_id, group_name)
      grouping = create_grouping(group_name) unless grouping

      mail_chimp_account.set_interest_attribute_for_list(group: attribute,
                                                         attribute: :interest_category_id,
                                                         list_id: list_id,
                                                         value: grouping['id'])
      mail_chimp_account.save
      mail_chimp_account.reload

      groups_already_present = fetch_groups_already_present_for_grouping(grouping)
      create_groups_for_grouping(grouping['id'], groups_to_add - groups_already_present)
    end

    def fetch_groups_already_present_for_grouping(grouping)
      gibbon_list.interest_categories(grouping['id'])
                 .interests
                 .retrieve['interests']
                 .map { |interest| interest['name'] }
    end

    def create_grouping(group_type)
      grouping_body = { title: _(group_type), type: 'hidden' }

      gibbon_list.interest_categories.create(body: grouping_body)

      find_grouping(nil, group_type)
    end

    def find_grouping(interest_category_id, group_name)
      groupings = gibbon_list.interest_categories.retrieve(params: { 'count': '100' })['categories']
      by_id = groupings.find { |grouping| grouping['id'] == interest_category_id }
      by_id || groupings.find { |grouping| grouping['title'] == _(group_name) }
    rescue Gibbon::MailChimpError => error
      raise unless does_not_have_interest_groups_enabled?(error)
    end

    def does_not_have_interest_groups_enabled?(error)
      error.message.include?('code 211')
    end

    def create_groups_for_grouping(grouping_id, interests)
      interests.reject(&:blank?).each do |interest|
        begin
          gibbon_list.interest_categories(grouping_id).interests.create(body: { name: interest })
        rescue Gibbon::MailChimpError => error
          break if maximum_number_of_interests_per_list?(error)
          raise unless already_exists_on_list?(error)
        end
      end
    end

    def already_exists_on_list?(error)
      error.status_code == 400 && error.detail =~ /Cannot add .* because it already exists on the list/
    end

    def maximum_number_of_interests_per_list?(error)
      error.status_code == 400 && error.detail =~ /Cannot have more than .* interests per list/
    end

    def gibbon_list
      gibbon_wrapper.gibbon_list_object(list_id)
    end
  end
end
