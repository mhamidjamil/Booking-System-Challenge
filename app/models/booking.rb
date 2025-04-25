class Booking < ApplicationRecord
  belongs_to :user
  has_many :rooms, dependent: nil
  has_many :booking_audit_logs, dependent: :destroy

  validates :start_time, :end_time, :status, presence: true
  validate :max_three_rooms, on: :create
  validate :rooms_availability
  validate :only_active_rooms

  enum :status, { pending: 'pending', confirmed: 'confirmed', cancelled: 'cancelled' }

  before_save :calculate_price

  def calculate_price
    duration_in_hours = ((end_time - start_time) / 1.hour).ceil
    base_price = rooms.sum { |room| room.price_per_hour * duration_in_hours }
    self.total_price = duration_in_hours > 4 ? base_price * 0.9 : base_price
  end

  def max_three_rooms
    errors.add(:base, 'Cannot book more than 3 rooms') if rooms.size > 3
  end

  def rooms_availability
    rooms.each do |room|
      conflicting_booking = Booking.joins(:rooms)
                                   .where(rooms: { id: room.id })
                                   .where.not(id: id)
                                   .where.not(status: 'cancelled')
                                   .exists?(['start_time < ? AND end_time > ?', end_time,
                                             start_time])

      errors.add(:base, "Room #{room.name} is already booked for this time period") if conflicting_booking
    end
  end

  def only_active_rooms
    rooms.each do |room|
      errors.add(:base, "Room #{room.name} is not active") unless room.active?
    end
  end
end
