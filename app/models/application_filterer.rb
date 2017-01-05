class ApplicationFilterer
  attr_accessor :filters

  FILTERS_TO_DISPLAY = [].freeze

  FILTERS_TO_HIDE = [].freeze

  def initialize(filters = nil)
    @filters = filters || {}
    @filters.map { |k, v| @filters[k] = v.strip if v.is_a?(String) }
  end

  def filter(scope:, account_lists:)
    self.class.filter_classes.each do |klass|
      scope = klass.new(account_lists).query(scope, filters) || scope
    end
    scope
  end

  def self.config(account_lists)
    filter_classes.map do |klass|
      filter = klass.new(account_lists)
      filter if filter.display_filter_option? && !filter.empty?
    end.compact
  end

  def self.filter_classes
    @filter_classes ||= (self::FILTERS_TO_DISPLAY + self::FILTERS_TO_HIDE).sort.map do |class_name|
      "#{to_s.split('::').first}::Filter::#{class_name}".constantize
    end
  end
end
