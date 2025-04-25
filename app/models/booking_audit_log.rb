class BookingAuditLog < ApplicationRecord
  belongs_to :user
  belongs_to :booking

  def parsed_metadata
    JSON.parse(metadata) rescue {}
  end
end
