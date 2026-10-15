module Api
  module Public
    class AppointmentsController < ApplicationController
      def create
        business = Business.find_by!(slug: params[:slug])
        service = business.services.active.find(params[:serviceId])
        starts_at = Time.iso8601(params[:startsAt].to_s)
        ends_at = starts_at + service.duration_minutes.minutes

        # Serialise bookings per business so the availability check and the
        # insert below are one atomic step.
        business.with_lock do
          if Appointment.overlapping(business_id: business.id, starts_at: starts_at, ends_at: ends_at).exists?
            return render_conflict
          end

          unless bookable_slot?(business, service, starts_at)
            return render json: { message: "That time is outside the available booking slots." },
                          status: :unprocessable_content
          end

          appointment = business.appointments.new(
            service: service,
            customer_name: params[:customerName],
            customer_email: params[:customerEmail],
            starts_at: starts_at,
            ends_at: ends_at
          )

          if appointment.save
            render json: {
              id: appointment.id,
              startsAt: appointment.starts_at.iso8601,
              endsAt: appointment.ends_at.iso8601,
              serviceName: service.name,
            }, status: :created
          else
            render json: { message: appointment.errors.full_messages.to_sentence }, status: :unprocessable_content
          end
        end
      rescue ArgumentError
        render json: { message: "startsAt must be a valid ISO 8601 timestamp." }, status: :unprocessable_content
      rescue ActiveRecord::RecordNotUnique
        render_conflict
      end

      private

      # A start time is bookable only if the calculator would offer it:
      # inside business hours, on the slot grid, in the future, and with
      # room for the whole service duration.
      def bookable_slot?(business, service, starts_at)
        date = starts_at.in_time_zone(business.time_zone).to_date
        AvailabilityCalculator.new(business: business, service: service, date: date).call.any? { |slot| slot == starts_at }
      end

      def render_conflict
        render json: { message: "This time slot is no longer available." }, status: :conflict
      end
    end
  end
end
