require "rails_helper"

RSpec.describe "Business hours and service deletion", type: :request do
  let(:owner) { create(:user) }
  let(:business) { create(:business, owner: owner) }

  before { create(:business_member, business: business, user: owner, role: :owner) }

  describe "PUT /api/businesses/:id/hours" do
    def put_hours(body)
      put "/api/businesses/#{business.id}/hours", params: body.to_json,
          headers: auth_headers(owner).merge("CONTENT_TYPE" => "application/json")
    end

    it "replaces the week with valid entries" do
      put_hours(hours: [{ dayOfWeek: 1, startLabel: "09:00", endLabel: "17:00" }])

      expect(response).to have_http_status(:ok)
      expect(json.first).to include("dayOfWeek" => 1, "startLabel" => "09:00", "endLabel" => "17:00")
    end

    [
      ["a non-array hours value", { hours: "nope" }],
      ["an object instead of an array", { hours: { "a" => 1 } }],
      ["a missing hours key", {}],
      ["non-object entries", { hours: ["x", 3] }],
      ["a garbage time label", { hours: [{ dayOfWeek: 1, startLabel: "abc", endLabel: "17:00" }] }],
      ["an out-of-range time label", { hours: [{ dayOfWeek: 1, startLabel: "09:00", endLabel: "25:99" }] }],
      ["a missing time label", { hours: [{ dayOfWeek: 1, endLabel: "17:00" }] }],
      ["a garbage day of week", { hours: [{ dayOfWeek: "abc", startLabel: "09:00", endLabel: "17:00" }] }],
    ].each do |label, body|
      it "returns 422 for #{label}" do
        create(:business_hour, business: business, day_of_week: 2)

        put_hours(body)

        expect(response).to have_http_status(:unprocessable_content)
        expect(business.business_hours.count).to eq(1) # existing hours untouched
      end
    end
  end

  describe "DELETE /api/businesses/:id/services/:id" do
    let(:service) { create(:service, business: business) }

    it "deletes a service with no appointments" do
      delete "/api/businesses/#{business.id}/services/#{service.id}", headers: auth_headers(owner)

      expect(response).to have_http_status(:no_content)
      expect(Service.exists?(service.id)).to be(false)
    end

    it "returns 422 with a message when the service has appointments" do
      create(:appointment, business: business, service: service)

      delete "/api/businesses/#{business.id}/services/#{service.id}", headers: auth_headers(owner)

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["message"]).to match(/appointments/i)
      expect(Service.exists?(service.id)).to be(true)
    end
  end
end
