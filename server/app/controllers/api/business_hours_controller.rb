module Api
  class BusinessHoursController < ApplicationController
    include BusinessScoped

    def show
      render json: @business.business_hours.order(:day_of_week).map { |h| hour_summary(h) }
    end

    # Replaces the whole week in one call: entries is an array of
    # { dayOfWeek, startLabel, endLabel }. A day left out of the array is
    # simply closed that day (no BusinessHour row for it).
    def update
      require_owner!
      entries = Array(params[:hours])

      ActiveRecord::Base.transaction do
        @business.business_hours.delete_all
        entries.each do |entry|
          @business.business_hours.create!(
            day_of_week: entry[:dayOfWeek],
            start_minute: BusinessHour.label_to_minutes(entry[:startLabel]),
            end_minute: BusinessHour.label_to_minutes(entry[:endLabel])
          )
        end
      end

      render json: @business.business_hours.reload.order(:day_of_week).map { |h| hour_summary(h) }
    rescue ActiveRecord::RecordInvalid => e
      render json: { message: e.record.errors.full_messages.to_sentence }, status: :unprocessable_content
    end

    private

    def hour_summary(hour)
      { dayOfWeek: hour.day_of_week, startLabel: hour.start_label, endLabel: hour.end_label }
    end
  end
end
