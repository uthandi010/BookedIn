require "rails_helper"

RSpec.describe AvailabilityCalculator do
  # Pick a fixed future Monday so "day of week" and "is this in the past"
  # behave predictably no matter when the suite runs.
  let(:monday) do
    today = Date.current
    days_until_monday = (1 - today.wday) % 7
    days_until_monday = 7 if days_until_monday.zero? # always a *future* Monday, even if today is one
    today + days_until_monday
  end

  let(:business) { create(:business) }
  let(:service) { create(:service, business: business, duration_minutes: 60) }

  def call(date: monday, staff_user_id: nil)
    described_class.new(business: business, service: service, date: date, staff_user_id: staff_user_id).call
  end

  context "when the business has no hours configured for that day" do
    it "returns no slots" do
      expect(call).to eq([])
    end
  end

  context "when the business is open 09:00-12:00 with a 60 minute service" do
    before { create(:business_hour, business: business, day_of_week: 1, start_minute: 9 * 60, end_minute: 12 * 60) }

    it "returns slots every 30 minutes that still fit before closing" do
      slots = call
      labels = slots.map { |t| t.strftime("%H:%M") }

      # 09:00, 09:30, 10:00, 10:30, 11:00 all leave room for a 60-minute
      # service before the 12:00 close. 11:30 would run until 12:30, so it
      # must not appear.
      expect(labels).to eq(["09:00", "09:30", "10:00", "10:30", "11:00"])
    end

    it "excludes a slot that overlaps an existing confirmed appointment" do
      create(:appointment, business: business, service: service,
                            starts_at: monday.in_time_zone.change(hour: 10),
                            ends_at: monday.in_time_zone.change(hour: 11))

      labels = call.map { |t| t.strftime("%H:%M") }
      expect(labels).not_to include("09:30", "10:00", "10:30")
      expect(labels).to include("09:00", "11:00")
    end

    it "does not let a cancelled appointment block a slot" do
      create(:appointment, business: business, service: service,
                            starts_at: monday.in_time_zone.change(hour: 10),
                            ends_at: monday.in_time_zone.change(hour: 11),
                            status: :cancelled)

      expect(call.map { |t| t.strftime("%H:%M") }).to include("10:00")
    end

    it "returns no slots at all once the day is fully booked" do
      create(:appointment, business: business, service: service,
                            starts_at: monday.in_time_zone.change(hour: 9),
                            ends_at: monday.in_time_zone.change(hour: 12))

      expect(call).to eq([])
    end

    it "scopes the overlap check to a specific staff member when asked" do
      staff_a = create(:user)
      staff_b = create(:user)
      create(:appointment, business: business, service: service, staff_user_id: staff_a.id,
                            starts_at: monday.in_time_zone.change(hour: 10),
                            ends_at: monday.in_time_zone.change(hour: 11))

      # Staff A is booked at 10:00, so that slot should disappear for them...
      expect(call(staff_user_id: staff_a.id).map { |t| t.strftime("%H:%M") }).not_to include("10:00")
      # ...but staff B has no appointments, so their calendar is untouched.
      expect(call(staff_user_id: staff_b.id).map { |t| t.strftime("%H:%M") }).to include("10:00")
    end
  end

  context "when the service is longer than the entire open window" do
    before { create(:business_hour, business: business, day_of_week: 1, start_minute: 9 * 60, end_minute: 9 * 60 + 30) }
    let(:service) { create(:service, business: business, duration_minutes: 90) }

    it "returns no slots" do
      expect(call).to eq([])
    end
  end

  context "when the requested date is today" do
    before { create(:business_hour, business: business, day_of_week: Date.current.wday, start_minute: 0, end_minute: 24 * 60) }

    it "does not return a slot that has already passed" do
      travel_to Date.current.in_time_zone.change(hour: 14) do
        slots = described_class.new(business: business, service: service, date: Date.current).call
        expect(slots).to all(be >= Time.current)
      end
    end
  end
end
