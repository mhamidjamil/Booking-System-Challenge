class Booking < ApplicationRecord
  belongs_to :user
  has_many :rooms

  validates :start_time, :end_time, :status, presence: true
  validate :max_three_rooms, on: :create
  validate :rooms_availability
  validate :only_active_rooms

  enum status: { pending: "pending", confirmed: "confirmed", cancelled: "cancelled" }

  before_save :calculate_price

  def calculate_price
    duration_in_hours = ((end_time - start_time) / 1.hour).ceil
    base_price = rooms.sum { |room| room.price_per_hour * duration_in_hours }

    self.total_price = base_price
    apply_discount(duration_in_hours)
  end

  def apply_discount(hours)
    if hours > 4
      self.total_price *= 0.9 # 10% discount for bookings > 4 hours
    end
  end

  def max_three_rooms
    if rooms.size > 3
      errors.add(:base, "Cannot book more than 3 rooms in a single transaction")
    end
  end

  def rooms_availability
    rooms.each do |room|
      # Check if room is already booked in another booking during this time
      if room.booking_id.present? && room.booking_id != id &&
         room.booking.start_time < end_time &&
         room.booking.end_time > start_time
        errors.add(:base, "Room #{room.name} is already booked during that time")
      end
    end
  end

  def only_active_rooms
    rooms.each do |room|
      unless room.active?
        errors.add(:base, "Room #{room.name} is not available for booking")
      end
    end
  end
end
