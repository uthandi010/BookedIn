# Throttles unauthenticated, abuse-prone endpoints. Limits are per client IP
# and can be tuned via ENV.
class Rack::Attack
  # The test env uses a null cache store, which would never count requests.
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new if Rails.env.test?

  # Specs opt in explicitly so unrelated request specs are never throttled.
  Rack::Attack.enabled = !Rails.env.test?

  PUBLIC_LIMIT = Integer(ENV.fetch("RATE_LIMIT_PUBLIC_PER_MINUTE", 60))
  AUTH_LIMIT = Integer(ENV.fetch("RATE_LIMIT_AUTH_PER_MINUTE", 10))

  throttle("public/availability", limit: PUBLIC_LIMIT, period: 1.minute) do |req|
    req.ip if req.get? && req.path.match?(%r{\A/api/public/businesses/[^/]+/availability\z})
  end

  throttle("public/booking", limit: 10, period: 1.minute) do |req|
    req.ip if req.post? && req.path.match?(%r{\A/api/public/businesses/[^/]+/appointments\z})
  end

  throttle("auth", limit: AUTH_LIMIT, period: 1.minute) do |req|
    req.ip if req.post? && %w[/api/auth/login /api/auth/register].include?(req.path)
  end

  self.throttled_responder = lambda do |request|
    retry_after = (request.env["rack.attack.match_data"] || {})[:period]
    [
      429,
      { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s },
      [ { message: "Too many requests. Please try again shortly." }.to_json ]
    ]
  end
end
