class CredentialValidator < ActiveModel::Validator
  def validate(record)
    # we don't want this error to show up if there is already an error
    return if record.errors[:organization_id].present? || record.errors[:person_id].present?
    return if valid_credentials?(record)
    record.errors[:base] << _('Your credentials for %{org} are invalid.').localize % { org: record.organization }
  end

  private

  def valid_credentials?(record)
    return false unless record.username.present? && record.password.present? || record.token.present?
    return record.organization.api(record).validate_credentials
  rescue OrgAccountInvalidCredentialsError
    return false
  rescue DataServerError => e
    return false if e.message.include?('user')
    raise
  end
end
