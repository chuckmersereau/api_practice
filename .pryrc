require "#{Rails.root}/dev/rails_c_funcs"
require 'awesome_print'
AwesomePrint.pry!

unless ENV['DEV_USER_ID'] && dev_user
  p 'Who are you? (User id)'
  dev_user_id = $stdin.gets.chomp
  dev_user(dev_user_id)
end

if dev_user
  p "Logging actions as: #{dev_user}"
else
  p 'Error logging in dev user'
end
