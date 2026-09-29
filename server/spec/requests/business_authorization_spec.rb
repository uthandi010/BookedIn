require "rails_helper"

RSpec.describe "Business authorization", type: :request do
  describe "POST /api/businesses" do
    it "makes the creator the owner" do
      owner = create(:user)

      post "/api/businesses", params: { name: "Acme Salon", slug: "acme-salon" }, headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(json["myRole"]).to eq("Owner")
    end
  end

  describe "GET /api/businesses/:id" do
    it "returns the business to a member" do
      owner = create(:user)
      business = create(:business, owner: owner, name: "Acme Salon")
      create(:business_member, business: business, user: owner, role: :owner)

      get "/api/businesses/#{business.id}", headers: auth_headers(owner)

      expect(response).to have_http_status(:ok)
      expect(json["name"]).to eq("Acme Salon")
    end

    it "403s for a non-member" do
      business = create(:business)
      create(:business_member, business: business, user: business.owner, role: :owner)
      outsider = create(:user)

      get "/api/businesses/#{business.id}", headers: auth_headers(outsider)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "a non-member" do
    it "cannot list members, services, hours, or appointments" do
      owner = create(:user)
      business = create(:business, owner: owner)
      create(:business_member, business: business, user: owner, role: :owner)
      outsider = create(:user)

      get "/api/businesses/#{business.id}/members", headers: auth_headers(outsider)
      expect(response).to have_http_status(:forbidden)

      get "/api/businesses/#{business.id}/services", headers: auth_headers(outsider)
      expect(response).to have_http_status(:forbidden)

      get "/api/businesses/#{business.id}/hours", headers: auth_headers(outsider)
      expect(response).to have_http_status(:forbidden)

      get "/api/businesses/#{business.id}/appointments", headers: auth_headers(outsider)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "invitations" do
    let(:owner) { create(:user) }
    let(:business) { create(:business, owner: owner) }

    before { create(:business_member, business: business, user: owner, role: :owner) }

    it "lets the owner invite an existing user as staff" do
      staff = create(:user, email: "staff@example.com")

      post "/api/businesses/#{business.id}/members",
        params: { email: "staff@example.com", role: "staff" },
        headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(json["role"]).to eq("Staff")
      expect(business.business_members.staff.where(user: staff)).to exist
    end

    it "rejects inviting someone as owner" do
      create(:user, email: "wouldbeowner@example.com")

      post "/api/businesses/#{business.id}/members",
        params: { email: "wouldbeowner@example.com", role: "owner" },
        headers: auth_headers(owner)

      expect(response).to have_http_status(:bad_request)
    end

    it "404s when inviting an email with no account" do
      post "/api/businesses/#{business.id}/members",
        params: { email: "nobody@example.com", role: "staff" },
        headers: auth_headers(owner)

      expect(response).to have_http_status(:not_found)
    end

    it "does not let a staff member invite others" do
      staff = create(:user)
      create(:business_member, business: business, user: staff, role: :staff)
      create(:user, email: "another@example.com")

      post "/api/businesses/#{business.id}/members",
        params: { email: "another@example.com", role: "staff" },
        headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "managing services" do
    let(:owner) { create(:user) }
    let(:business) { create(:business, owner: owner) }
    let(:staff) { create(:user) }

    before do
      create(:business_member, business: business, user: owner, role: :owner)
      create(:business_member, business: business, user: staff, role: :staff)
    end

    it "lets the owner create a service" do
      post "/api/businesses/#{business.id}/services",
        params: { name: "Haircut", durationMinutes: 30, priceCents: 2500 },
        headers: auth_headers(owner)

      expect(response).to have_http_status(:created)
      expect(json["name"]).to eq("Haircut")
    end

    it "does not let staff create a service" do
      post "/api/businesses/#{business.id}/services",
        params: { name: "Haircut", durationMinutes: 30 },
        headers: auth_headers(staff)

      expect(response).to have_http_status(:forbidden)
    end

    it "lets staff view services" do
      create(:service, business: business, name: "Manicure")

      get "/api/businesses/#{business.id}/services", headers: auth_headers(staff)

      expect(response).to have_http_status(:ok)
      expect(json.map { |s| s["name"] }).to include("Manicure")
    end
  end
end
