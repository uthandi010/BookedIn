FactoryBot.define do
  factory :business_member do
    business
    user
    role { :staff }
  end
end
