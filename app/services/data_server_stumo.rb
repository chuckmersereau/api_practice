class DataServerStumo < DataServer
  def import_profiles
    designation_profiles = org.designation_profiles
                              .where(user_id: org_account.person_id)

    if org.profiles_url.present?
      check_credentials!

      profiles.each do |profile|
        Retryable.retryable do
          designation_profile = find_or_create_designation_profile(
            user_id: org_account.person_id,
            profile_data: profile
          )

          import_profile_balance(designation_profile)
          AccountList::FromProfileLinker.new(designation_profile, org_account)
                                        .link_account_list! unless designation_profile.account_list
        end
      end
    else
      # still want to update balance if possible
      designation_profiles.each do |designation_profile|
        Retryable.retryable do
          import_profile_balance(designation_profile)
          AccountList::FromProfileLinker.new(designation_profile, org_account)
                                        .link_account_list! unless designation_profile.account_list
        end
      end
    end

    designation_profiles.reload
  end

  private

  def find_or_create_designation_profile(user_id:, profile_data:)
    name = profile_data[:name]
    code = profile_data[:code]

    attributes = {
      user_id: user_id,
      code: code
    }

    # If `code` isn't present - we assume that we want to find
    # by another level of specificity, ie: `name`
    #
    # So, we add in the `name` as part of our query attributes.
    #
    # Assuming that a profile's `code` is unique in relation to `user_id`,
    # and a profile's `name` is _not_ unique in relation to `user_id`,
    # we don't want to find a profile by _only_ `name` and `user_id`.
    #
    # This would cause profiles with the same name but different code to be
    # found - thus, we keep `code` in the query attributes - even if it's blank.
    attributes[:name] = name if code.blank?

    org.designation_profiles
       .where(attributes)
       .first_or_create
       .tap { |profile| profile.update(name: name) if name.present? }
  end
end
