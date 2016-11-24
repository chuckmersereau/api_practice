class PrayerLettersAccountPolicy < AccountListChildrenPolicy
  def sync?
    resource_owner?
  end
end
