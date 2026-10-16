require "rails_helper"

RSpec.describe "Rate limiting", type: :request do
  around do |example|
    Rack::Attack.enabled = true
    Rack::Attack.cache.store.clear
    example.run
  ensure
    Rack::Attack.enabled = false
    Rack::Attack.cache.store.clear
  end

  it "throttles repeated login attempts with a 429" do
    statuses = Array.new(Rack::Attack::AUTH_LIMIT + 1) do
      post "/api/auth/login", params: { email: "nobody@example.com", password: "wrong" }
      response.status
    end

    expect(statuses.first).to eq(401)
    expect(statuses.last).to eq(429)
    expect(response.headers["Retry-After"]).to be_present
    expect(json["message"]).to match(/too many requests/i)
  end

  it "throttles repeated public availability lookups" do
    statuses = Array.new(Rack::Attack::PUBLIC_LIMIT + 1) do
      get "/api/public/businesses/nope/availability", params: { serviceId: 1, date: "2030-01-01" }
      response.status
    end

    expect(statuses.first).to eq(404)
    expect(statuses.last).to eq(429)
  end

  it "throttles repeated public booking attempts" do
    statuses = Array.new(11) do
      post "/api/public/businesses/nope/appointments", params: {}
      response.status
    end

    expect(statuses.last).to eq(429)
  end
end
