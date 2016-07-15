class PreferencesController < ApplicationController
  def index
    @page_title = _('{{title}}')
  end
end
