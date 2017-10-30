module Filtering
  module Contacts
    def permitted_filters
      @permitted_filters ||= reversible_filters_including_filter_flags + [:account_list_id, :any_tags]
    end

    def reversible_filters
      ::Contact::Filterer::FILTERS_TO_DISPLAY.collect(&:underscore).collect(&:to_sym) +
        ::Contact::Filterer::FILTERS_TO_HIDE.collect(&:underscore).collect(&:to_sym)
    end

    def reversible_filters_including_filter_flags
      reversible_filters.map do |reversible_filter|
        [reversible_filter, "reverse_#{reversible_filter}".to_sym]
      end.flatten
    end

    def excluded_filter_keys_from_casting_validation
      [:donation_amount_range]
    end
  end
end
