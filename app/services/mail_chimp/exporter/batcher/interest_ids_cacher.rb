# This class will retrieve mail chimp interests and cache them for future calls.
class MailChimp::Exporter
  class Batcher
    class InterestIdsCacher
      attr_reader :mail_chimp_account, :gibbon_list

      def initialize(mail_chimp_account, gibbon_list)
        @mail_chimp_account = mail_chimp_account
        @gibbon_list = gibbon_list
      end

      def cached_interest_ids(attribute)
        cache_interest_ids(attribute) if mail_chimp_account.send(attribute).blank?

        mail_chimp_account.send(attribute)
      end

      private

      def cache_interest_ids(attribute)
        interests = gibbon_list.interest_categories(mail_chimp_account.send(attribute))
                               .interests.retrieve(params: { 'count': '100' })['interests']
        interests = Hash[interests.map { |interest| [interest['name'], interest['id']] }]
        mail_chimp_account.update_attribute(attribute, interests)
        mail_chimp_account.reload
      end
    end
  end
end
