class Person::NetworkSerializer < ApplicationSerializer
  # has_many :facebook_accounts
  # has_many :linkedin_accounts
  # has_many :twitter_accounts
  # has_many :websites

  attributes :facebook_accounts, :linkedin_accounts, :twitter_accounts, :websites
end
