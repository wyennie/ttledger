FactoryBot.define do
  factory :mention do
    entity
    association :mentionable, factory: :page
    position { 0 }
  end
end
