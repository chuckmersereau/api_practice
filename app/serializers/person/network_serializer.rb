class Person::NetworkSerializer < ApplicationSerializer
  has_many :facebook_accounts
  has_many :linkedin_accounts
  has_many :twitter_accounts
  has_many :websites
end
