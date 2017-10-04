FactoryGirl.define do
  factory :import do
    source 'twitter'
    association :account_list
    association :user
    importing false
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
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_0_export_gifts.xml')) }
  end

  factory :tnt_import_no_gifts, parent: :tnt_import do
    association :account_list
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_no_gifts.xml')) }
  end

  factory :tnt_import_with_personal_gift, parent: :tnt_import do
    association :account_list
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_2_export_with_personal_gift.xml')) }
  end

  factory :tnt_import_gifts_added, parent: :tnt_import do
    association :account_list
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_gifts_1added.xml')) }
  end

  factory :tnt_import_gifts_multiple_same_day, parent: :tnt_import do
    association :account_list
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_gifts_multiple_same_day.xml')) }
  end

  factory :tnt_import_first_email_not_preferred, parent: :tnt_import do
    association :account_list
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_row_multi_email.yaml')) }
  end

  factory :tnt_import_3_0_appeals, parent: :tnt_import do
    association :account_list
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_0_export_appeals.xml')) }
  end

  factory :tnt_import_3_2_campaigns, parent: :tnt_import do
    association :account_list
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_campaigns.xml')) }
  end

  factory :tnt_import_campaigns_and_promises, parent: :tnt_import do
    association :account_list
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_3_2_with_campaign_promises.xml')) }
  end

  factory :csv_import, parent: :import do
    association :account_list
    source 'csv'
    file { File.new(Rails.root.join('spec/fixtures/sample_csv_to_import.csv')) }
  end

  factory :csv_import_with_bom, parent: :import do
    association :account_list
    source 'csv'
    file { File.new(Rails.root.join('spec/fixtures/sample_csv_with_bom.csv')) }
  end

  factory :csv_import_invalid, parent: :import do
    association :account_list
    source 'csv'
    file { File.new(Rails.root.join('spec/fixtures/csv_invalid.csv')) }
  end

  factory :csv_import_custom_headers, parent: :import do
    association :account_list
    source 'csv'
    file { File.new(Rails.root.join('spec/fixtures/sample_csv_with_custom_headers.csv')) }
  end

  factory :google_import, parent: :import do
    source 'google'
  end

  factory :csv_import_with_mappings, parent: :csv_import_custom_headers do
    after :build do |import|
      import.in_preview = true
    end

    after :create do |import|
      CsvImport.new(import).update_cached_file_data

      import.file_headers_mappings = {
        'church'               => 'church',
        'city'                 => 'city',
        'commitment_amount'    => 'amount',
        'commitment_currency'  => 'currency',
        'commitment_frequency' => 'frequency',
        'country'              => 'country',
        'email_1'              => 'email_address',
        'first_name'           => 'fname',
        'full_name'            => 'fullname',
        'greeting'             => 'greeting',
        'envelope_greeting'    => 'mailing_greeting',
        'last_name'            => 'lname',
        'likely_to_give'       => 'likely_giver',
        'metro_area'           => 'metro',
        'newsletter'           => 'newsletter',
        'notes'                => 'extra_notes',
        'phone_1'              => 'phone',
        'region'               => 'region',
        'send_appeals'         => 'appeals',
        'spouse_email'         => 'spouse_email_address',
        'spouse_first_name'    => 'spouse_fname',
        'spouse_last_name'     => 'spouse_lname',
        'spouse_phone'         => 'spouse_phone_number',
        'state'                => 'province',
        'status'               => 'status',
        'street'               => 'street',
        'tags'                 => 'tags',
        'website'              => 'website',
        'zip'                  => 'zip_code'
      }

      import.file_constants_mappings = {
        'commitment_currency' => {
          'cad' => 'CAD',
          'usd' => ''
        },
        'commitment_frequency' => {
          '1_0' => 'Monthly',
          '' => ''
        },
        'likely_to_give' => {
          'most_likely' => 'Yes',
          'least_likely' => 'No'
        },
        'newsletter' => {
          'both' => 'Both'
        },
        'send_appeals' => {
          'true' => 'Yes',
          'false' => 'No'
        },
        'status' => {
          'partner_financial' => 'Praying and giving',
          'partner_pray' => 'Praying'
        }
      }

      import.save
    end
  end

  factory :tnt_import_multi_org, parent: :import do
    association :account_list
    source 'tnt'
    file { File.new(Rails.root.join('spec/fixtures/tnt/tnt_export_multi_org.xml')) }
  end
end
