class PrayerLettersAccountPolicy < AccountListPolicy
  def sync?
    resource_owner?
  end
end
