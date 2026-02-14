class Rootein < ApplicationRecord
  has_many :completions, dependent: :destroy
  validates :name, presence: true
end
