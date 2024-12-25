FactoryBot.define do
  factory :weapon do
    damage { "1d8" }
    range { 30 }

    after(:create) do |weapon|
      create(:item, item_type: weapon)
    end
  end
end
