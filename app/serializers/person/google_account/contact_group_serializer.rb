class Person::GoogleAccount::ContactGroupSerializer < ApplicationSerializer
  type :contact_groups

  attributes :title, :tag

  def title
    object.title.gsub('System Group: ', '')
  end

  def tag
    title.downcase.tr(' ', '-')
  end
end
