module Api
  module Public
    class AvailabilityController < ApplicationController
      def index
        business = Business.find_by!(slug: params[:slug])
        service = business.services.active.find(params[:serviceId])
        date = Date.iso8601(params[:date])

        slots = AvailabilityCalculator.new(business: business, service: service, date: date).call
        render json: { date: date.iso8601, slots: slots.map(&:iso8601) }
      rescue Date::Error, TypeError
        render json: { message: "date must be in YYYY-MM-DD format." }, status: :unprocessable_content
      end
    end
  end
end
