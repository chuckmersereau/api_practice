class AppealContactSerializer < ApplicationSerializer
  belongs_to :appeal
  belongs_to :contact
end
