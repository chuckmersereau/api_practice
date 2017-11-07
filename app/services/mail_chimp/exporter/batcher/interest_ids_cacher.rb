# This class will retrieve mail chimp interests and cache them for future calls.
class MailChimp::Exporter
  class Batcher
    class InterestIdsCacher
      attr_reader :mail_chimp_account, :gibbon_wrapper, :list_id

      def initialize(mail_chimp_account, gibbon_wrapper, list_id)
        @mail_chimp_account = mail_chimp_account
        @gibbon_wrapper = gibbon_wrapper
        @list_id = list_id
      end

      def cached_interest_ids(attribute)
        cache_interest_ids(attribute) if interests_from_database(attribute).blank?

        interests_from_database(attribute)
      end

      def interests_from_database(attribute)
        mail_chimp_account.get_interest_attribute_for_list(group: attribute,
                                                           attribute: :interest_ids,
                                                           list_id: list_id)
      end

      private

      def cache_interest_ids(attribute)
        grouping_id_key = fetch_interest_id_from_attribute(attribute)
        interests = gibbon_list.interest_categories(grouping_id_key)
                               .interests.retrieve(params: { 'count': '100' })['interests']
        interests = Hash[interests.map { |interest| [interest['name'], interest['id']] }]
        mail_chimp_account.set_interest_attribute_for_list(group: attribute, attribute: :interest_ids, list_id: list_id, value: interests)
        mail_chimp_account.save(validate: false)
        mail_chimp_account.reload
      end

      def fetch_interest_id_from_attribute(attribute)
        mail_chimp_account.get_interest_attribute_for_list(group: attribute,
                                                           attribute: :interest_category_id,
                                                           list_id: list_id)
      end

      def gibbon_list
        gibbon_wrapper.gibbon_list_object(list_id)
      end
    end
  end
end
