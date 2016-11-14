class MailChimpAccountPolicy < AccountListPolicy
  def sync?
    resource_owner?
  end
end
