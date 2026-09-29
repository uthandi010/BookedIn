FactoryBot.define do
  factory :service do
    business
    sequence(:name) { |n| "Service #{n}" }
    duration_minutes { 30 }
    price_cents { 2500 }
    description { "A test service." }
    active { true }
  end
end
