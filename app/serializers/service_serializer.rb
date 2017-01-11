class ServiceSerializer < ApplicationSerializer
  def id
    nil
  end

  def created_at
    @created_at ||= Time.current
  end

  def updated_in_db_at
    nil
  end
  alias updated_at updated_in_db_at
end
