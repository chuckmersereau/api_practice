class PersonWithParentContactSerializer < ApplicationSerializer
  type :people

  delegate :anniversary_day,
           :anniversary_month,
           :anniversary_year,
           :birthday_day,
           :birthday_month,
           :birthday_year,
           :created_at,
           :deceased,
           :email_addresses,
           :employer,
           :facebook_accounts,
           :family_relationships,
           :first_name,
           :gender,
           :last_name,
           :legal_first_name,
           :linkedin_accounts,
           :marital_status,
           :middle_name,
           :occupation,
           :optout_enewsletter,
           :parent_contact,
           :phone_numbers,
           :suffix,
           :title,
           :twitter_accounts,
           :updated_at,
           :uuid,
           :websites,
           to: :object

  attributes :anniversary_day,
             :anniversary_month,
             :anniversary_year,
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

  has_one :parent_contact
end
