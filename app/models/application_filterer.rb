class ApplicationFilterer
  attr_accessor :resource_scope, :filters

  FILTERS_TO_DISPLAY = [].freeze

  FILTERS_TO_HIDE = [].freeze

  def initialize(filters = nil)
    @filters = filters || {}
    @filters.map { |k, v| @filters[k] = v.strip if v.is_a?(String) }
  end

  def filter(resource_scope, account_list)
    self.class.filter_classes.each do |klass|
      resource_scope = klass.query(resource_scope, @filters, account_list) || resource_scope
    end
    resource_scope.all
  end

  def self.config(account_list)
    filter_classes.map do |klass|
      klass.config(account_list)
    end.compact
  end

  def self.filter_classes
    @filter_classes ||= (self::FILTERS_TO_DISPLAY + self::FILTERS_TO_HIDE).sort.map do |class_name|
      "#{to_s.split('::').first}::Filter::#{class_name}".constantize
    end
  end
end
