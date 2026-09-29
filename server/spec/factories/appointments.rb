FactoryBot.define do
  factory :appointment do
    business
    service
    customer_name { "Jane Customer" }
    customer_email { "jane@example.com" }
    starts_at { 1.day.from_now.change(hour: 10, min: 0) }
    ends_at { starts_at + (service&.duration_minutes || 30).minutes }
    status { :confirmed }
  end
end
