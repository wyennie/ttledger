FactoryBot.define do
  factory :entity_kind do
    sequence(:name) { |n| "kind#{n}" }
    campaign { Campaign.first || create(:campaign) }
  end
end
