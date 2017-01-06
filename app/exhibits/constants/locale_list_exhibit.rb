class LocaleListExhibit < DisplayCase::Exhibit
  include ApplicationHelper

  def self.applicable_to?(object)
    object.class.name == 'Constants::LocaleList'
  end

  def display_name(name, code)
    format '%s (%s)', name, code
  end
end
