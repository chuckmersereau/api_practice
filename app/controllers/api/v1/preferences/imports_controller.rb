class Api::V1::Preferences::ImportsController < Api::V1::Preferences::BaseController
  def create
    build_import
    return render_success if save_import
    render_errors
  end

  protected

  def load_preferences
    @preferences ||= {}
    load_google_import_preferences
  end

  def build_import
    @import ||= import_scope.build
    @import.attributes = import_params
  end

  def save_import
    @import.save
  end

  def import_scope
    current_account_list.imports.where(user: current_user)
  end

  def import_params
    import_params = params[:import]
    return {} unless import_params
    import_params
      .permit(:source, :source_account_id, :file, :file_cache, :tags,
              :override, :import_by_group, :in_preview, groups: [])
      .merge(group_tags: params.require(:import).fetch(:group_tags, nil).try(:permit!))
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

  def render_success
    render json: { success: true }
  end

  def render_errors
    render json: { errors: @import.errors.full_messages }, status: 400
  end
end
