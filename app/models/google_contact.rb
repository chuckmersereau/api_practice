class GoogleContact < ApplicationRecord
  belongs_to :person
  belongs_to :contact
  belongs_to :google_account, class_name: 'Person::GoogleAccount'
  belongs_to :picture

  serialize :last_data, Hash
end
