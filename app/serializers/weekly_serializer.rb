class WeeklySerializer < ApplicationSerializer
  attributes :id,
             :answer,
             :question_id,
             :session_id
end
