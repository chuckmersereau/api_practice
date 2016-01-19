require "#{Rails.root}/dev/rails_c_funcs"
require 'awesome_print'
AwesomePrint.pry!

unless dev_user || Rails.env.test? || Rails.env.development?
  p 'Who are you? (User id)'
  dev_user_id = $stdin.gets.chomp
  dev_user(dev_user_id)
end

if dev_user
  p "Logging actions as: #{dev_user}"
else
  p 'Error logging in dev user' unless Rails.env.test? || Rails.env.development?
end
