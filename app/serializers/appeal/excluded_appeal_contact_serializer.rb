class Appeal::ExcludedAppealContactSerializer < ApplicationSerializer
  type :excluded_appeal_contacts
  attributes :reasons

  belongs_to :appeal
  belongs_to :contact
end
