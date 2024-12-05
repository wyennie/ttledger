FactoryBot.define do
  factory :campaign do
    name        { "Campaign Title" }
    description { "This is the description of the campaign." }

    trait :without_description do
      description { nil }
    end

    after(:create) do |campaign|
      create(:role, campaign: campaign, role_type: :gamemaster)
    end
  end
end
