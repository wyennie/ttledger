FactoryBot.define do
  factory :user do
    username              { Faker::Internet.username(specifier: 5..10) }
    name                  { Faker::Name.name }
    email                 { Faker::Internet.email }
    password              { "password" }
    password_confirmation { "password" }
  end
end
