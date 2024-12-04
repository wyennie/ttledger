FactoryBot.define do
  factory :campaign do
    name        { "Campaign Title" }
    description { "This is the description of the campaign." }

    association :creator, factory: :user

    trait :without_description do
      description { nil }
    end

    after(:create) do |campaign|
      create(:role, user: campaign.creator, campaign: campaign, role_type: :gamemaster)
    end
  end
end
