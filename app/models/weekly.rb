class Weekly < ApplicationRecord

  PERMITTED_ATTRIBUTES = [ :answer,
                           :question_id,
                           :sid
  ].freeze


  before_save :set_nil

  def set_nil
    if self.sid == nil
      self.sid = 1
    end
  end

  def serializer_class
    WeeklySerializer
  end


end
