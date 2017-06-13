class PersonSerializer < ApplicationSerializer
  include DisplayCase::ExhibitsHelper

  attributes :anniversary_day,
             :anniversary_month,
             :anniversary_year,
             :avatar,
             :birthday_day,
             :birthday_month,
             :birthday_year,
             :deceased,
             :employer,
             :first_name,
             :gender,
             :last_name,
             :legal_first_name,
             :marital_status,
             :middle_name,
             :occupation,
             :optout_enewsletter,
             :suffix,
             :title

  has_many :email_addresses
  has_many :facebook_accounts
  has_many :family_relationships
  has_many :linkedin_accounts
  has_many :phone_numbers
  has_many :twitter_accounts
  has_many :websites

  def avatar
    person_exhibit.avatar(:large)
  end

  def person_exhibit
    exhibit(object)
  end
end
