class User::OptionSerializer < ApplicationSerializer
  attributes :created_at,
             :key,
             :value,
             :updated_at
end
