class Booking < ApplicationRecord
  belongs_to :user
  belongs_to :room

  validates :start_time, :end_time, :status, presence: true
  validate :no_overlap, on: :create
  validate :max_rooms_limit, on: :create

  enum status: { pending: "pending", confirmed: "confirmed", cancelled: "cancelled" }


  before_save :calculate_price

  def calculate_price
    hours = ((end_time - start_time) / 1.hour).ceil
    base_price = room.price_per_hour * hours

    self.total_price = base_price
    apply_discount(hours)
  end

  def apply_discount(hours)
    if hours > 4
      self.total_price *= 0.9 # 10% discount
    end
  end

  def max_rooms_limit
    return if user.bookings.where(start_time: start_time).distinct.count(:room_id) < 3

    errors.add(:base, "Cannot book more than 3 rooms at the same time")
  end

  def no_overlap
    overlapping = Booking.where(room_id: room_id)
                         .where.not(id: id)
                         .where("start_time < ? AND end_time > ?", end_time, start_time)
    errors.add(:base, "Room is already booked for the selected time") if overlapping.exists?
  end
end
