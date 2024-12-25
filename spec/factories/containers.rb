FactoryBot.define do
  factory :container do
    capacity { 10 }

    after(:create) do |container|
      create(:item, item_type: container)
    end
  end
end
