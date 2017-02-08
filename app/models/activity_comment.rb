class ActivityComment < ApplicationRecord
  has_paper_trail on: [:destroy],
                  meta: { related_object_type: 'Activity',
                          related_object_id: :activity_id }

  belongs_to :activity, counter_cache: true, touch: true
  belongs_to :person

  validates :body, presence: true

  before_create :ensure_person

  PERMITTED_ATTRIBUTES = [:body, :updated_in_db_at, :uuid].freeze

  private

  def ensure_person
    self.person = Thread.current[:user] unless person_id
  end
end
