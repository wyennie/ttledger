FactoryBot.define do
  factory :entity do
    sequence(:name) { |n| "Entity #{n}" }
    summary { "A test entity." }
    campaign { Campaign.first || create(:campaign) }
    entity_kind { campaign.entity_kinds.find_by(name: "character") || create(:entity_kind, campaign: campaign) }
  end
end
