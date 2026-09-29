require "rails_helper"

RSpec.describe Appointment, type: :model do
  let(:business) { create(:business) }
  let(:service) { create(:service, business: business, duration_minutes: 30) }
  let(:start_time) { 1.day.from_now.change(hour: 10, min: 0) }

  it "is valid with a business, service, customer, and non-overlapping time range" do
    appointment = build(:appointment, business: business, service: service, starts_at: start_time,
                                       ends_at: start_time + 30.minutes)
    expect(appointment).to be_valid
  end

  it "requires ends_at to be after starts_at" do
    appointment = build(:appointment, business: business, service: service, starts_at: start_time,
                                       ends_at: start_time)
    expect(appointment).not_to be_valid
  end

  it "requires a valid customer email" do
    appointment = build(:appointment, business: business, service: service, customer_email: "not-an-email")
    expect(appointment).not_to be_valid
  end

  describe "double-booking prevention" do
    before do
      create(:appointment, business: business, service: service, starts_at: start_time,
                            ends_at: start_time + 30.minutes)
    end

    it "rejects an appointment that exactly matches an existing one" do
      conflicting = build(:appointment, business: business, service: service, starts_at: start_time,
                                         ends_at: start_time + 30.minutes)
      expect(conflicting).not_to be_valid
      expect(conflicting.errors[:base]).to include("This time slot is no longer available")
    end

    it "rejects an appointment that partially overlaps an existing one" do
      overlapping = build(:appointment, business: business, service: service,
                                         starts_at: start_time + 15.minutes,
                                         ends_at: start_time + 45.minutes)
      expect(overlapping).not_to be_valid
    end

    it "allows a back-to-back appointment that starts exactly when the other ends" do
      back_to_back = build(:appointment, business: business, service: service,
                                          starts_at: start_time + 30.minutes,
                                          ends_at: start_time + 60.minutes)
      expect(back_to_back).to be_valid
    end

    it "allows an overlapping time on a different business" do
      other_business_service = create(:service)
      elsewhere = build(:appointment, business: other_business_service.business, service: other_business_service,
                                       starts_at: start_time, ends_at: start_time + 30.minutes)
      expect(elsewhere).to be_valid
    end

    it "does not conflict with a cancelled appointment" do
      business.appointments.first.update!(status: :cancelled)
      appointment = build(:appointment, business: business, service: service, starts_at: start_time,
                                         ends_at: start_time + 30.minutes)
      expect(appointment).to be_valid
    end

    it "still allows the same time slot for a different staff member" do
      staff_a = create(:user)
      staff_b = create(:user)
      business.appointments.first.update!(staff_user_id: staff_a.id)

      for_staff_b = build(:appointment, business: business, service: service, staff_user_id: staff_b.id,
                                         starts_at: start_time, ends_at: start_time + 30.minutes)
      expect(for_staff_b).to be_valid
    end
  end
end
