# A dedicated controller for the one state transition a business member can
# make on an appointment from the dashboard: cancelling it. Kept separate
# from AppointmentsController (which is nested under a business and
# membership-scoped via BusinessScoped) because here the business has to be
# derived *from* the appointment first.
module Api
  class AppointmentCancellationsController < ApplicationController
    before_action :authenticate_user!

    def create
      appointment = Appointment.find(params[:appointment_id])
      membership = appointment.business.business_members.find_by(user_id: current_user.id)
      raise ApplicationController::AuthorizationError if membership.nil?

      appointment.update!(status: :cancelled)
      render json: { id: appointment.id, status: "Cancelled" }
    end
  end
end
