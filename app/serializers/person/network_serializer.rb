class Person::NetworkSerializer < ApplicationSerializer
  attributes :facebook_accounts, :linkedin_accounts, :twitter_accounts, :websites
end
