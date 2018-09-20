class QuestionSerializer < ApplicationSerializer
  #SERVICE_ATTRIBUTES = [:question_id, :question].freeze
  attributes :question_id,
             :question
end
