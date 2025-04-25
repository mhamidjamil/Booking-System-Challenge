module Api
  class BookingsController < ApplicationController
    before_action :set_user
    before_action :set_booking, only: %i[update destroy cancel_booking audit_logs]

    def index
      bookings = @user.bookings.includes(:rooms) # Eager loading to avoid N+1 queries
      render json: bookings.as_json(include: {
                                      rooms: {
                                        only: %i[id name capacity price_per_hour]
                                      }
                                    })
    end

    def create
      booking = @user.bookings.new(booking_params)

      # Assign rooms to booking
      room_ids = params[:booking][:room_ids] || []
      rooms = Room.where(id: room_ids)

      if room_ids.size != rooms.size
        missing_rooms = room_ids - rooms.pluck(:id)
        render json: {
          errors: ["Some rooms are not available for booking: #{missing_rooms.join(', ')}"]
        }, status: :unprocessable_entity
        return
      end

      booking.rooms = rooms

      if booking.save
        duration_hours = ((booking.end_time - booking.start_time) / 3600).ceil
        discount_applied = duration_hours > 4 ? (booking.total_price * 0.1).round(2) : 0

        response_data = {
          message: 'Booking created successfully.',
          booking: {
            id: booking.id,
            user_id: booking.user_id,
            rooms: booking.rooms.map { |r| { id: r.id, name: r.name } },
            start_time: booking.start_time,
            end_time: booking.end_time,
            total_price: booking.total_price,
            status: booking.status,
            duration_hours: duration_hours
          },
          pricing_details: {
            base_price: (booking.total_price / (discount_applied.positive? ? 0.9 : 1)).round(2),
            discount_applied: discount_applied,
            discount_percentage: discount_applied.positive? ? '10%' : '0%'
          }
        }

        if discount_applied.positive?
          response_data[:message] =
            "Booking created successfully with 10% discount for #{duration_hours} hour booking"
        end

        BookingAuditLog.create!(
          user: booking.user,
          booking: booking,
          action: 'created',
          metadata: {
            start_time: booking.start_time,
            end_time: booking.end_time,
            room_ids: booking.rooms.map(&:id),
            status: booking.status,
            discount_applied: discount_applied,
            discount_percentage: discount_applied.positive? ? '10%' : '0%',
            base_price: (booking.total_price / (discount_applied.positive? ? 0.9 : 1)).round(2)
          }.to_json
        )

        render json: response_data, status: :created
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
      if @booking.cancelled?
        render json: { error: 'Booking is already cancelled' }, status: :unprocessable_entity
        return
      end

      cancellation_time = Time.current
      booking_start_time = @booking.start_time
      hours_before_start = ((booking_start_time - cancellation_time) / 1.hour).round
      old_total_price = @booking.total_price

      if hours_before_start < 24
        refund_amount = (old_total_price * 0.95).round(2)
        cancellation_fee = (old_total_price * 0.05).round(2)

        @booking.update(status: 'cancelled', total_price: cancellation_fee)

        BookingAuditLog.create!(
          user: @booking.user,
          booking: @booking,
          action: 'cancelled',
          metadata: {
            original_total_price: old_total_price,
            refund_amount: refund_amount,
            cancellation_fee: cancellation_fee,
            cancelled_at: cancellation_time,
            within_24_hours: true
          }.to_json
        )

        render json: {
          message: 'Booking cancelled successfully with 5% cancellation fee',
          refund_amount: refund_amount,
          cancellation_fee: cancellation_fee,
          status: 'cancelled'
        }

      else
        refund_amount = old_total_price.round(2)

        @booking.update(status: 'cancelled')

        BookingAuditLog.create!(
          user: @booking.user,
          booking: @booking,
          action: 'cancelled',
          metadata: {
            original_total_price: old_total_price,
            refund_amount: refund_amount,
            cancellation_fee: 0,
            cancelled_at: cancellation_time,
            within_24_hours: false
          }
        )

        render json: {
          message: 'Booking cancelled successfully with full refund',
          refund_amount: refund_amount,
          cancellation_fee: 0,
          status: 'cancelled'
        }
      end
    end

    def audit_logs
      logs = @booking.booking_audit_logs.order(created_at: :desc)
      render json: logs.map { |log|
        {
          action: log.action,
          user: log.user&.email,
          created_at: log.created_at,
          metadata: log.parsed_metadata
        }
      }
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
end
