FactoryBot.define do
  factory :business_hour do
    business
    day_of_week { 1 } # Monday
    start_minute { 9 * 60 }  # 09:00
    end_minute { 17 * 60 }   # 17:00
  end
end
