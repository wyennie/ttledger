FactoryBot.define do
  factory :item do
    name { "Default Item" }
    weight { 1.0 }
    value { 10 }
    count { 1 }
    description { "A simple item description." }
    association :character
    association :item_type, factory: :item_type
    container { nil } # Optional; can associate with another item

    # Nested factory for an item in a container
    factory :contained_item do
      association :container, factory: :item
    end
  end
end
