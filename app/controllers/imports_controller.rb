class ImportsController < ApplicationController
  def create
    if import_params
      import = current_account_list.imports.new(import_params)
      import.user_id = current_user.id

      if import.save
        if import.in_preview?
          redirect_to import_path(import.id)
          return
        else
          show_importing_notice(import)
        end
      else
        flash[:alert] = import.errors.full_messages.join('<br>').html_safe
      end
    end

    redirect_to :back
  end

  def show
    find_import
  end

  def update
    find_import
    @import.update(import_params)

    if @import.in_preview?
      redirect_to @import
    else
      show_importing_notice(@import)
      redirect_to accounts_path
    end
  end

  def sample
    respond_to do |format|
      format.csv do
        render_csv(_('Sample_MPDX_Upload'))
      end
    end
  end

  def csv_preview_partial
    find_import
    @csv_import = CsvImport.new(@import)
    render layout: false
  end

  private

  def show_importing_notice(import)
    flash[:notice] = _('MPDX is currently importing your contacts from %{source}. You will receive an email when the import is complete.')
                     .localize % { source: import.user_friendly_source }
  end

  def find_import
    @import = current_account_list.imports.find(params[:id])
  end

  def import_params
    group_tags = params.require(:import).fetch(:group_tags, nil).try(:permit!)
    params.require(:import)
      .permit(:source, :source_account_id, :file, :file_cache, :tags, :override, :import_by_group,
              :in_preview, groups: [])
      .merge(group_tags: group_tags)
  end
end
