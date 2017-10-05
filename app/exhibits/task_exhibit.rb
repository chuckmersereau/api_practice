class TaskExhibit < DisplayCase::Exhibit
  def self.applicable_to?(object)
    object.class.name == 'Task'
  end

  def to_s
    subject
  end

  def css_class
    if to_model.start_at < Time.now then 'high'
    elsif to_model.start_at < Time.now + 1.day then 'mid'
    else ''
    end
  end

  def completed_at
    to_model.completed_at ? @context.l(to_model.completed_at.to_datetime) : ''
  end

  def start_at
    to_model.start_at ? @context.l(to_model.start_at.to_datetime) : ''
  end
end
