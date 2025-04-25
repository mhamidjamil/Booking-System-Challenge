class CreateBookingAuditLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :booking_audit_logs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :booking, null: false, foreign_key: true
      t.string :action
      t.text :metadata

      t.timestamps
    end
  end
end
