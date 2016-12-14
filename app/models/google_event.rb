class GoogleEvent < ApplicationRecord
  belongs_to :activity
  belongs_to :google_integration
end
