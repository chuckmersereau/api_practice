class ImportMailerPreview < ActionMailer::Preview
  def success
    import = Import.first
    ImportMailer.success(import)
  end

  def failed
    import = Import.first
    ImportMailer.failed(import)
  end

  def credentials_error
    account = Person::OrganizationAccount.first
    ImportMailer.credentials_error(account)
  end
end
