require "rails_helper"

RSpec.describe "Auth", type: :request do
  describe "POST /api/auth/register" do
    it "creates an account and returns a token" do
      post "/api/auth/register", params: { name: "Ada Lovelace", email: "ada@example.com", password: "Password123!" }

      expect(response).to have_http_status(:created)
      expect(json["token"]).to be_present
      expect(json["email"]).to eq("ada@example.com")
    end

    it "rejects a duplicate email" do
      create(:user, email: "duplicate@example.com")

      post "/api/auth/register", params: { name: "Someone Else", email: "duplicate@example.com", password: "Password123!" }

      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects a password shorter than 8 characters" do
      post "/api/auth/register", params: { name: "Short Pw", email: "short@example.com", password: "1234" }

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /api/auth/login" do
    it "returns a token for correct credentials" do
      create(:user, email: "grace@example.com", password: "Password123!")

      post "/api/auth/login", params: { email: "grace@example.com", password: "Password123!" }

      expect(response).to have_http_status(:ok)
      expect(json["token"]).to be_present
    end

    it "rejects an incorrect password" do
      create(:user, email: "grace2@example.com", password: "Password123!")

      post "/api/auth/login", params: { email: "grace2@example.com", password: "WrongPassword!" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects an unknown email" do
      post "/api/auth/login", params: { email: "nobody@example.com", password: "Password123!" }

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "a protected endpoint without a token" do
    it "returns 401" do
      get "/api/businesses"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
