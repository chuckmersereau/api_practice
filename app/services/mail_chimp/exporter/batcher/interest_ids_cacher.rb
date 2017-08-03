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
        cache_interest_ids(attribute) if mail_chimp_account.send(attribute).blank?

        mail_chimp_account.send(attribute)
      end

      private

      def cache_interest_ids(attribute)
        grouping_id_key = fetch_grouping_id_key_from_attribute(attribute)
        interests = gibbon_list.interest_categories(mail_chimp_account.send(grouping_id_key))
                               .interests.retrieve(params: { 'count': '100' })['interests']
        interests = Hash[interests.map { |interest| [interest['name'], interest['id']] }]
        mail_chimp_account.update_attribute(attribute, interests)
        mail_chimp_account.reload
      end

      def fetch_grouping_id_key_from_attribute(attribute)
        attribute.to_s.sub('interest', 'grouping').chomp('s')
      end

      def gibbon_list
        gibbon_wrapper.gibbon_list_object(list_id)
      end
    end
  end
end
