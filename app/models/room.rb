class Room < ApplicationRecord
  belongs_to :booking, optional: true

  validates :name, :capacity, :price_per_hour, presence: true
  validates :price_per_hour, numericality: { greater_than_or_equal_to: 0 }
  scope :active, -> { where(active: true) }
end
