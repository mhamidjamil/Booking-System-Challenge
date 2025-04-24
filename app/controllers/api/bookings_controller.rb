class Api::BookingsController < ApplicationController
  before_action :set_user
  before_action :set_booking, only: [ :update, :destroy, :cancel_booking ]

  def index
    bookings = @user.bookings.includes(:rooms) # Eager loading to avoid N+1 queries
    render json: bookings.as_json(include: {
      rooms: {
        only: [ :id, :name, :capacity, :price_per_hour ]
      }
    })
  end

  def create
    booking = @user.bookings.new(booking_params)

    # Assign rooms to booking
    room_ids = params[:booking][:room_ids] || []
    rooms = Room.where(id: room_ids, active: true)

    # Check if all requested rooms were found and are available
    if room_ids.size != rooms.size
      missing_rooms = room_ids - rooms.pluck(:id)
      render json: {
        errors: [ "Some rooms are not available for booking: #{missing_rooms.join(', ')}" ]
      }, status: :unprocessable_entity
      return
    end

    booking.rooms = rooms

    if booking.save
      render json: {
        message: "Booking created successfully.",
        booking: {
          id: booking.id,
          user_id: booking.user_id,
          rooms: booking.rooms.map { |r| { id: r.id, name: r.name } },
          start_time: booking.start_time,
          end_time: booking.end_time,
          total_price: booking.total_price,
          status: booking.status
        }
      }, status: :created
    else
      render json: { errors: booking.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @booking.update(booking_params)
      render json: @booking
    else
      render json: { errors: @booking.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @booking.destroy
    head :no_content
  end

  def cancel_booking
    @booking.update(status: "cancelled")
    render json: { message: "Booking cancelled successfully" }
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def set_booking
    @booking = @user.bookings.find(params[:id])
  end

  def booking_params
    params.require(:booking).permit(:start_time, :end_time, :status, room_ids: [])
  end
end
