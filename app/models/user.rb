class User < ApplicationRecord
  has_many :bookings

  validates :name, :email, :role, presence: true
  validates :role, inclusion: { in: %w[customer admin] }
end
