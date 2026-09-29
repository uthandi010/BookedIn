module Api
  module Public
    class AppointmentsController < ApplicationController
      def create
        business = Business.find_by!(slug: params[:slug])
        service = business.services.active.find(params[:serviceId])
        starts_at = Time.iso8601(params[:startsAt].to_s)

        appointment = business.appointments.new(
          service: service,
          customer_name: params[:customerName],
          customer_email: params[:customerEmail],
          starts_at: starts_at,
          ends_at: starts_at + service.duration_minutes.minutes
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
      rescue ArgumentError
        render json: { message: "startsAt must be a valid ISO 8601 timestamp." }, status: :unprocessable_content
      end
    end
  end
end
