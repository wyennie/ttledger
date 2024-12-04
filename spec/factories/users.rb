FactoryBot.define do
  factory :user do
    name                  { "Test User" }
    email                 { "testuser@example.com" }
    password              { "password" }
    password_confirmation { "password" }

    trait :with_unique_email do
      email { "uniqueuser#{rand(1000)}@example.com"} 
    end
  end
end
