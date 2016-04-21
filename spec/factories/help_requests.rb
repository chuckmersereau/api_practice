# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :help_request do
    name 'MyString'
    browser 'MyText'
    problem 'MyText'
    email 'foo@cru.org'
    user_id 1
    account_list_id 1
    session 'MyText'
    user_preferences 'MyText'
    account_list_settings 'MyText'
    request_type 'Problem'
    factory :help_request_with_attachment do
      file Rack::Test::UploadedFile.new(File.open(File.join(Rails.root, '/spec/fixtures/obiee_json.txt')))
    end
  end
end
