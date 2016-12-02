require_relative 'seeders/application_seeder'

if Rails.env.development?
  ApplicationSeeder.new.seed
else
  raise "Seeding aborted! You are running Rails in #{ Rails.env } environment. Seeding is not supported."
end
