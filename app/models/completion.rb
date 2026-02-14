class Completion < ApplicationRecord
  belongs_to :rootein
  validates :completed_on, presence: true, uniqueness: { scope: :rootein_id, message: "can only be completed once per day" }
end
