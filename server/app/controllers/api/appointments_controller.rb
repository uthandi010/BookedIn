module Api
  class AppointmentsController < ApplicationController
    include BusinessScoped

    def index
      appointments = @business.appointments.includes(:service, :staff).order(:starts_at)
      render json: appointments.map { |a| appointment_summary(a) }
    end

    private

    def appointment_summary(appointment)
      {
        id: appointment.id,
        serviceName: appointment.service.name,
        staffName: appointment.staff&.name,
        customerName: appointment.customer_name,
        customerEmail: appointment.customer_email,
        startsAt: appointment.starts_at.iso8601,
        endsAt: appointment.ends_at.iso8601,
        status: appointment.status.capitalize,
      }
    end
  end
end
