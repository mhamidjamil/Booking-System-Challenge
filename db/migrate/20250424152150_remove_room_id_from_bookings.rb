class RemoveRoomIdFromBookings < ActiveRecord::Migration[7.2]
  def change
    remove_column :bookings, :room_id, :integer
  end
end
