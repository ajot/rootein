class Rootein < ApplicationRecord
  belongs_to :user
  has_many :completions, dependent: :destroy
  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :created_at) }
  scope :slacking, -> { active.select { |r| r.current_streak == 0 } }
  scope :on_target, -> { active.select { |r| r.current_streak > 0 } }

  def current_streak
    streak = 0
    date = Date.today
    while completions.exists?(completed_on: date)
      streak += 1
      date -= 1.day
    end
    streak
  end
end
