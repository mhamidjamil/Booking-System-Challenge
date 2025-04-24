class AddBookingToRooms < ActiveRecord::Migration[7.2]
  def change
    add_reference :rooms, :booking, null: true, foreign_key: true
  end
end
