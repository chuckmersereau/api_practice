class Api::V1::Preferences::ImportsController < Api::V1::Preferences::BaseController
  protected

  def load_preferences
    @preferences ||= {}
    load_google_import_preferences
  end

  private

  def load_google_import_preferences
    @preferences.merge!(
      google_accounts: current_user.google_accounts.map do |account|
        {
          id: account.id,
          email: account.email,
          contact_groups: account.contact_groups.map.with_index do |group, index|
            {
              id: group.id,
              index: index,
              title: group.title.gsub('System Group: ', ''),
              tag: group.title.gsub('System Group: ', '').downcase.tr(' ', '-')
            }
          end
        }
      end,
      tags: current_account_list.contact_tags.map { |t| { text: t.to_s } }
    )
  end
end
