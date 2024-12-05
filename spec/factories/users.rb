FactoryBot.define do
  factory :user do
    username              { "TestUser" }
    name                  { "Test User" }
    email                 { "testuser@example.com" }
    password              { "password" }
    password_confirmation { "password" }

    trait :with_unique_email_and_username do
      username { "uniqueusername#{rand(1000)}" }
      email    { "uniqueuser#{rand(1000)}@example.com" }
    end
  end
end
