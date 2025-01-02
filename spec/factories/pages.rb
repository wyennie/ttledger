FactoryBot.define do
  factory :page do
    title { Faker::Lorem.words }
    campaign { Campaign.first || create(:campaign) }
  end
end
