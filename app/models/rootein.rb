class Rootein < ApplicationRecord
  has_many :completions, dependent: :destroy
  validates :name, presence: true

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
