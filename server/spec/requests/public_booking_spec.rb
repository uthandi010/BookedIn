require "rails_helper"

RSpec.describe "Public booking", type: :request do
  let(:owner) { create(:user) }
  let(:business) { create(:business, owner: owner, slug: "glow-salon") }
  let(:service) { create(:service, business: business, name: "Haircut", duration_minutes: 30, active: true) }
  let(:monday) do
    today = Date.current
    days_until_monday = (1 - today.wday) % 7
    days_until_monday = 7 if days_until_monday.zero?
    today + days_until_monday
  end

  before do
    create(:business_member, business: business, user: owner, role: :owner)
    service
    create(:business_hour, business: business, day_of_week: 1, start_minute: 9 * 60, end_minute: 12 * 60)
  end

  describe "GET /api/public/businesses/:slug" do
    it "returns the business name and its active services, without requiring auth" do
      create(:service, business: business, name: "Hidden", active: false)

      get "/api/public/businesses/glow-salon"

      expect(response).to have_http_status(:ok)
      names = json["services"].map { |s| s["name"] }
      expect(names).to include("Haircut")
      expect(names).not_to include("Hidden")
    end

    it "404s for an unknown slug" do
      get "/api/public/businesses/does-not-exist"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/public/businesses/:slug/availability" do
    it "returns open slots for that date" do
      get "/api/public/businesses/glow-salon/availability", params: { serviceId: service.id, date: monday.iso8601 }

      expect(response).to have_http_status(:ok)
      expect(json["slots"]).not_to be_empty
    end
  end

  describe "POST /api/public/businesses/:slug/appointments" do
    let(:slot_time) { monday.in_time_zone.change(hour: 9) }

    it "books an available slot" do
      post "/api/public/businesses/glow-salon/appointments", params: {
        serviceId: service.id, customerName: "Jane Doe", customerEmail: "jane@example.com",
        startsAt: slot_time.iso8601
      }

      expect(response).to have_http_status(:created)
      expect(Appointment.count).to eq(1)
    end

    it "rejects booking the same slot twice (no double-booking)" do
      post "/api/public/businesses/glow-salon/appointments", params: {
        serviceId: service.id, customerName: "Jane Doe", customerEmail: "jane@example.com",
        startsAt: slot_time.iso8601
      }

      post "/api/public/businesses/glow-salon/appointments", params: {
        serviceId: service.id, customerName: "Someone Else", customerEmail: "else@example.com",
        startsAt: slot_time.iso8601
      }

      expect(response).to have_http_status(:conflict)
      expect(json["message"]).to match(/no longer available/i)
      expect(Appointment.count).to eq(1)
    end

    it "returns 409 when the database unique index catches a racing insert" do
      allow_any_instance_of(Appointment).to receive(:save).and_raise(ActiveRecord::RecordNotUnique)

      post "/api/public/businesses/glow-salon/appointments", params: {
        serviceId: service.id, customerName: "Jane Doe", customerEmail: "jane@example.com",
        startsAt: slot_time.iso8601
      }

      expect(response).to have_http_status(:conflict)
    end

    it "enforces uniqueness of confirmed slots at the database level" do
      create(:appointment, business: business, service: service, starts_at: slot_time, ends_at: slot_time + 30.minutes)
      dup = build(:appointment, business: business, service: service, starts_at: slot_time, ends_at: slot_time + 30.minutes)

      expect { dup.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    {
      "outside business hours" => 14,
      "before opening" => 7
    }.each do |label, hour|
      it "rejects a booking #{label}" do
        post "/api/public/businesses/glow-salon/appointments", params: {
          serviceId: service.id, customerName: "Jane", customerEmail: "jane@example.com",
          startsAt: monday.in_time_zone.change(hour: hour).iso8601
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(Appointment.count).to eq(0)
      end
    end

    it "rejects a start time that is off the slot grid" do
      post "/api/public/businesses/glow-salon/appointments", params: {
        serviceId: service.id, customerName: "Jane", customerEmail: "jane@example.com",
        startsAt: monday.in_time_zone.change(hour: 9, min: 10).iso8601
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a start time in the past" do
      post "/api/public/businesses/glow-salon/appointments", params: {
        serviceId: service.id, customerName: "Jane", customerEmail: "jane@example.com",
        startsAt: (monday - 7).in_time_zone.change(hour: 9).iso8601
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a booking that would run past closing time" do
      long = create(:service, business: business, name: "Long", duration_minutes: 90, active: true)

      post "/api/public/businesses/glow-salon/appointments", params: {
        serviceId: long.id, customerName: "Jane", customerEmail: "jane@example.com",
        startsAt: monday.in_time_zone.change(hour: 11).iso8601
      }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "no longer offers a slot as available once it is booked" do
      post "/api/public/businesses/glow-salon/appointments", params: {
        serviceId: service.id, customerName: "Jane Doe", customerEmail: "jane@example.com",
        startsAt: slot_time.iso8601
      }

      get "/api/public/businesses/glow-salon/availability", params: { serviceId: service.id, date: monday.iso8601 }

      expect(json["slots"]).not_to include(slot_time.iso8601)
    end
  end

  describe "cancelling frees the slot back up" do
    it "makes a cancelled appointment's slot available again" do
      slot_time = monday.in_time_zone.change(hour: 9)
      appointment = create(:appointment, business: business, service: service, starts_at: slot_time,
                                          ends_at: slot_time + 30.minutes)

      post "/api/appointments/#{appointment.id}/cancel", headers: auth_headers(owner)
      expect(response).to have_http_status(:ok)

      get "/api/public/businesses/glow-salon/availability", params: { serviceId: service.id, date: monday.iso8601 }
      expect(json["slots"]).to include(slot_time.iso8601)
    end

    it "does not let a non-member cancel someone else's appointment" do
      slot_time = monday.in_time_zone.change(hour: 9)
      appointment = create(:appointment, business: business, service: service, starts_at: slot_time,
                                          ends_at: slot_time + 30.minutes)
      outsider = create(:user)

      post "/api/appointments/#{appointment.id}/cancel", headers: auth_headers(outsider)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
