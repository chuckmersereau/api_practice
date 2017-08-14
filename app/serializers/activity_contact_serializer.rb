class ActivityContactSerializer < ApplicationSerializer
  include DisplayCase::ExhibitsHelper
  belongs_to :contact
  belongs_to :activity
end
