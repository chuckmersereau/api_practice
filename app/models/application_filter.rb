class ApplicationFilter
  class << self
    def config(account_list)
      {
        name: class_symbol,
        title: title,
        type: type,
        priority: priority,
        parent: parent,
        default_selection: default_selection
      }.merge(select_options(account_list)) if display_filter_option? && !empty?(account_list)
    end

    def query(resource, filters, user)
      filters[class_symbol] ||= default_selection if default_selection.present?
      return unless valid_filters?(filters)
      execute_query(resource, filters, user)
    end

    protected

    def filterer
      "#{to_s.split('::').first}::Filterer".constantize
    end

    def display_filter_option?
      filterer::FILTERS_TO_DISPLAY.index(name.demodulize).present?
    end

    def empty?(account_list)
      custom_options? ? custom_options(account_list).empty? : false
    end

    def custom_options?
      %w(radio dropdown checkbox multiselect dates daterange text).include?(type)
    end

    def priority
      filterer::FILTERS_TO_DISPLAY.index(name.demodulize) || 100
    end

    def parent
    end

    def select_options(account_list)
      return {
        multiple: %w(checkbox multiselect).include?(type),
        options: options(account_list)
      } if custom_options?
      {}
    end

    def options(account_list)
      default_options + custom_options(account_list)
    end

    def default_options
      return [] if %w(text dates daterange).include?(type)
      [{ name: '-- Any --', id: '', placeholder: _('None') }]
    end

    def default_selection
      return true if type == 'single_checkbox'
      ''
    end

    def custom_options(_account_list)
      []
    end

    def title
      raise "Must Override Superclass Method (#{name})"
    end

    def type
      nil
    end

    def execute_query(_contacts, _filters, _account_list)
    end

    def valid_filters?(filters)
      return false unless filters[class_symbol].present?
      return true unless filters[class_symbol].is_a?(Array)
      return true unless filters[class_symbol].first == ''
      false
    end

    def class_symbol
      name.demodulize.underscore.to_sym
    end

    def daterange_params(string)
      return {} unless string.is_a?(String) && string.include?(' - ')
      split = string.split(' - ')
      { start: parse_date(split.first).beginning_of_day,
        end: parse_date(split.last).end_of_day }
    end

    def parse_date(string)
      Date.strptime(string, '%m/%d/%Y')
    end
  end
end
