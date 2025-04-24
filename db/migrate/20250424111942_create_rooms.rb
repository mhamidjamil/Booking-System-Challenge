class CreateRooms < ActiveRecord::Migration[7.2]
  def change
    create_table :rooms do |t|
      t.string :name
      t.integer :capacity
      t.decimal :price_per_hour
      t.boolean :active

      t.timestamps
    end
  end
end
