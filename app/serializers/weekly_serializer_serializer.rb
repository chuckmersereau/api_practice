class WeeklySerializerSerializer < ApplicationSerializer
  attributes :id,
             :answer,
             :question_id

  has_many :questions
end
