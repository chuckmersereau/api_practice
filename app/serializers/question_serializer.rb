class QuestionSerializer < ApplicationSerializer
  #SERVICE_ATTRIBUTES = [:question_id, :question].freeze
  attributes :id,
             :question_id,
             :question
end
