class AnalyticsSerializer < ApplicationSerializer
  def id
    nil
  end

  def created_at
    @created_at ||= Time.current
  end
  alias updated_at created_at
end
