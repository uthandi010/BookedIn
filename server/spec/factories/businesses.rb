FactoryBot.define do
  factory :business do
    sequence(:name) { |n| "Test Business #{n}" }
    sequence(:slug) { |n| "test-business-#{n}" }
    owner factory: :user
  end
end
