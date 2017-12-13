# This class deals with duplicate donations during the import process.
# A mistake in previous versions of the import caused some donations to be duplicated,
# the duplicate donations belonged to different designation accounts.

class DonationImports::Base
  class MergeDonations
    attr_accessor :donations, :attributes, :verbose

    def initialize(donations, verbose: false)
      @donations = donations.to_a
      @attributes = {}.with_indifferent_access
      @verbose = verbose
    end

    def merge
      if donations.size <= 1
        if verbose
          log { format('Skipping single Donation<id: %p>', donations.first.id) }
        end
        return donations.first
      end

      find_attributes_from_all_donations
      merge_donations_into_one
    end

    private

    def mergeable_attributes
      @attributes_to_look_at ||= (Donation.attribute_names - %w(id created_at updated_at uuid)).map(&:to_sym)
    end

    def find_attributes_from_all_donations
      # Attributes might be missing if the value is imported from one
      # source but not from another (such as tnt_id, or appeal_id).
      @attributes = mergeable_attributes.each_with_object({}) do |attribute, hash|
        hash[attribute] = donations.collect(&attribute).compact.first
      end
    end

    def merge_donations_into_one
      log_merges if verbose

      donations[1..-1].each(&:destroy)
      donations.first.update!(attributes)
      donations.first
    end

    def log_merges
      log do
        format('Merging Donations<ids: %p> into Donation<id: %p> with attributes <%p>',
               donations[1..-1].map(&:id), donations.first.id, attributes)
      end
    end

    def log(&blk)
      # Because the sidekiq config sets the logging level to Fatal, log to
      # fatal so that we can see these in the logs
      Rails.logger.tagged('DonationDups[merge]') { Rails.logger.fatal(&blk) }
    end
  end
end
