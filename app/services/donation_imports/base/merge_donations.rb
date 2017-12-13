# This class deals with duplicate donations during the import process.
# A mistake in previous versions of the import caused some donations to be duplicated,
# the duplicate donations belonged to different designation accounts.

class DonationImports::Base
  class MergeDonations
    attr_accessor :donations, :attributes

    def initialize(donations)
      @donations = donations.to_a
      @attributes = {}.with_indifferent_access
    end

    def merge
      return donations.first if donations.size <= 1
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
      donations[1..-1].each(&:destroy)
      donations.first.update!(attributes)
      donations.first
    end
  end
end
