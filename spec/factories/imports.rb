# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :import do
    association :account_list
    association :user
    importing false
    source 'facebook'
    after :create do |i|
      i.user.email_addresses << create(:email_address)
    end
  end

  factory :tnt_import, parent: :import do
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export.xml')) }
    source 'tnt'
  end

  factory :tnt_import_non_donor, parent: :tnt_import do
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_non_donor.xml')) }
  end

  factory :tnt_import_short_donor_code, parent: :tnt_import do
    association :account_list, factory: :account_list_with_designation_profile
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_short_donor_code.xml')) }
  end

  factory :tnt_import_groups, parent: :tnt_import do
    association :account_list, factory: :account_list_with_designation_profile
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_groups.xml')) }
  end

  factory :tnt_import_multi_donor_accounts, parent: :tnt_import do
    association :account_list, factory: :account_list_with_designation_profile
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_multi_donor_accounts.xml')) }
  end

  factory :tnt_import_gifts, parent: :tnt_import do
    association :account_list
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_gifts.xml')) }
  end

  factory :tnt_import_gifts_added, parent: :tnt_import do
    association :account_list
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_gifts_1added.xml')) }
  end

  factory :tnt_import_first_email_not_preferred, parent: :tnt_import do
    association :account_list
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_row_multi_email.yaml')) }
  end
end
