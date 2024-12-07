FactoryBot.define do
  factory :campaign do
    name        { Faker::Book.title }
    description { Faker::Lorem.paragraph }

    trait :without_description do
      description { nil }
    end

    after(:create) do |campaign|
      create(:role, campaign: campaign, role_type: :gamemaster)
    end
  end
end
