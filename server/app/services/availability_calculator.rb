# Computes free appointment slots for a given business, service, and date.
#
# The algorithm:
#   1. Look up the business's opening hours for that day of week. No hours
#      configured for that day means the business is closed -> no slots.
#   2. Walk candidate slot start times across the open window, one every
#      SLOT_INTERVAL_MINUTES, each long enough to fit the service's duration.
#   3. Drop any candidate that overlaps an existing confirmed appointment
#      (optionally scoped to one staff member), and any candidate already in
#      the past.
class AvailabilityCalculator
  SLOT_INTERVAL_MINUTES = 30

  def initialize(business:, service:, date:, staff_user_id: nil)
    @business = business
    @service = service
    @date = date
    @staff_user_id = staff_user_id
  end

  # @return [Array<Time>] the start time of each available slot, in order.
  def call
    hours = @business.business_hours.find_by(day_of_week: @date.wday)
    return [] if hours.nil?

    duration = @service.duration_minutes
    latest_start = hours.end_minute - duration
    return [] if latest_start < hours.start_minute

    booked_ranges = Appointment.overlapping(
      business_id: @business.id,
      starts_at: day_start,
      ends_at: day_end,
      staff_user_id: @staff_user_id
    ).pluck(:starts_at, :ends_at)

    now = Time.current

    (hours.start_minute..latest_start).step(SLOT_INTERVAL_MINUTES).filter_map do |minute_offset|
      slot_start = day_start + minute_offset.minutes
      slot_end = slot_start + duration.minutes

      next if slot_start < now
      next if overlaps_any?(slot_start, slot_end, booked_ranges)

      slot_start
    end
  end

  private

  def overlaps_any?(slot_start, slot_end, booked_ranges)
    booked_ranges.any? { |booked_start, booked_end| slot_start < booked_end && slot_end > booked_start }
  end

  def day_start
    @day_start ||= @date.in_time_zone.beginning_of_day
  end

  def day_end
    @day_end ||= day_start.end_of_day
  end
end
