class Rootein < ApplicationRecord
  belongs_to :user
  has_many :completions, dependent: :destroy
  validates :name, presence: true

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :created_at) }
  scope :slacking, -> { active.select { |r| r.current_streak == 0 } }
  scope :on_target, -> { active.select { |r| r.current_streak > 0 } }

  def current_streak
    dates = completions.where("completed_on <= ?", Date.today)
                       .order(completed_on: :desc)
                       .pluck(:completed_on)
                       .to_set
    streak = 0
    date = Date.today
    while dates.include?(date)
      streak += 1
      date -= 1.day
    end
    streak
  end

  def days_since_last_completion
    last = completions.order(completed_on: :desc).first
    last ? (Date.today - last.completed_on).to_i : 999
  end
end
